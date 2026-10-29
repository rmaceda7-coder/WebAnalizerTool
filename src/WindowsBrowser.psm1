Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-DesktopSupport {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'The Windows UI Automation adapter requires Windows.'
    }
    if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
        throw 'Start PowerShell with -STA to use the desktop adapter.'
    }
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    Add-Type -AssemblyName System.Windows.Forms
    if (-not ('WebAnalyzer.NativeDesktop' -as [type])) {
        Add-Type -Path (Join-Path $PSScriptRoot 'NativeDesktop.cs')
    }
}

function Select-PrimaryBrowserWindow {
    <# Pure selection policy. Input order is desktop Z-order, highest first. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Windows)
    $eligible = @($Windows | Where-Object {
        $_.IsPrimary -and $_.ProcessName -eq 'chrome' -and $_.Visible -and
        -not $_.Minimized -and -not $_.Cloaked -and
        -not [string]::IsNullOrWhiteSpace($_.Title)
    })
    if ($eligible.Count -eq 0) {
        throw 'No eligible Chrome window exists on the Windows primary monitor. No other display was inspected for page content.'
    }
    return $eligible[0]
}

function Get-PageIdentity {
    param([Parameter(Mandatory)]$Window)
    $root = [System.Windows.Automation.AutomationElement]::FromHandle([IntPtr]$Window.Handle)
    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Document)
    $documents = @($root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition) |
        Where-Object { -not $_.Current.IsOffscreen })
    $pages = @()
    foreach ($document in $documents) {
        $value = $null
        if ($document.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$value)) {
            $url = $value.Current.Value
            if ($url -match '^https?://') {
                $pages += [pscustomobject]@{ Document = $document; Url = $url }
            }
        }
    }
    if ($pages.Count -ne 1) {
        throw "Expected exactly one visible HTTP(S) Document; found $($pages.Count). Cannot identify the selected page unambiguously."
    }
    return [pscustomobject]@{ Root = $root; Document = $pages[0].Document; Url = $pages[0].Url }
}

function Get-PrimaryBrowserContext {
    [CmdletBinding()]
    param()
    Assert-DesktopSupport
    $windows = [WebAnalyzer.NativeDesktop]::GetWindows()
    $window = Select-PrimaryBrowserWindow -Windows $windows
    $page = Get-PageIdentity -Window $window
    return [pscustomobject][ordered]@{
        SchemaVersion = 1
        CapturedAtUtc = [DateTime]::UtcNow.ToString('o')
        WindowHandle = $window.Handle
        ProcessId = $window.ProcessId
        Browser = 'chrome'
        Title = $window.Title
        Url = $page.Url
        Monitor = [pscustomobject]@{ Device = $window.MonitorDevice; IsPrimary = $true }
        Selection = 'PrimaryMonitorChromeZOrder'
        ForegroundWindowHandle = [WebAnalyzer.NativeDesktop]::ForegroundHandle()
    }
}

function Assert-ExpectedContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$ExpectedUrl,
        [Parameter(Mandatory)][long]$ExpectedWindowHandle
    )
    if (-not $Context.Monitor.IsPrimary -or
        $Context.WindowHandle -ne $ExpectedWindowHandle -or
        $Context.Url -cne $ExpectedUrl) {
        throw 'Browser context changed. Rediscover and confirm the current primary-display page before continuing.'
    }
}

function Get-BoundPage {
    param([string]$ExpectedUrl, [long]$ExpectedWindowHandle)
    $context = Get-PrimaryBrowserContext
    Assert-ExpectedContext -Context $context -ExpectedUrl $ExpectedUrl -ExpectedWindowHandle $ExpectedWindowHandle
    $window = [pscustomobject]@{ Handle = $context.WindowHandle }
    $page = Get-PageIdentity -Window $window
    if ($page.Url -cne $ExpectedUrl) { throw 'The selected page changed during discovery.' }
    return [pscustomobject]@{ Context = $context; Root = $page.Root; Document = $page.Document }
}

function Get-EditorElements {
    param($Document)
    $condition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Edit)
    return @($Document.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition) |
        Where-Object { $_.Current.IsEnabled -and -not $_.Current.IsOffscreen })
}

function Read-BrowserPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ExpectedUrl,
        [Parameter(Mandatory)][long]$ExpectedWindowHandle
    )
    $page = Get-BoundPage @PSBoundParameters
    $pattern = $null
    if (-not $page.Document.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$pattern)) {
        throw 'The selected page does not expose an accessibility TextPattern.'
    }
    $text = $pattern.DocumentRange.GetText(-1)
    $editors = @(Get-EditorElements -Document $page.Document | ForEach-Object {
        [pscustomobject]@{ Name = $_.Current.Name; AutomationId = $_.Current.AutomationId }
    })
    # A second identity check catches selection changes during the read.
    $null = Get-BoundPage @PSBoundParameters
    return [pscustomobject]@{ Context = $page.Context; Text = $text; Editors = $editors }
}

function Get-ExactEditor {
    param($Document, [string]$EditorName)
    $matches = @(Get-EditorElements -Document $Document | Where-Object { $_.Current.Name -ceq $EditorName })
    if ($matches.Count -ne 1) {
        throw "Expected one visible editor with the exact accessible name; found $($matches.Count). No input was sent."
    }
    return $matches[0]
}

function Get-ContentSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    # Newline-only differences do not make logically identical editor text differ.
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized)))).Replace('-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

function Assert-EditorFocus {
    param($Editor, [long]$WindowHandle)
    if ([WebAnalyzer.NativeDesktop]::ForegroundHandle() -ne $WindowHandle -or -not $Editor.Current.HasKeyboardFocus) {
        throw 'The target editor does not have keyboard focus. No further keys will be sent.'
    }
}

function New-EditorDesktop {
    # Private test seam. Public commands always use these real desktop operations.
    return @{
        BindPage = {
            param($Url, $Handle)
            Get-BoundPage -ExpectedUrl $Url -ExpectedWindowHandle $Handle
        }
        FindEditor = {
            param($Document, $Name)
            Get-ExactEditor -Document $Document -EditorName $Name
        }
        SnapshotClipboard = {
            $oldClipboard = [System.Windows.Forms.Clipboard]::GetDataObject()
            # Materialize formats before changing focus or replacing the clipboard.
            $savedClipboard = New-Object System.Windows.Forms.DataObject
            if ($null -ne $oldClipboard) {
                foreach ($format in $oldClipboard.GetFormats($false)) {
                    $savedClipboard.SetData($format, $oldClipboard.GetData($format, $false))
                }
            }
            return $savedClipboard
        }
        RestoreClipboard = {
            param($Snapshot)
            if ($Snapshot.GetFormats().Count -gt 0) {
                [System.Windows.Forms.Clipboard]::SetDataObject($Snapshot, $true)
            } else { [System.Windows.Forms.Clipboard]::Clear() }
        }
        FocusWindow = { param($Handle) [WebAnalyzer.NativeDesktop]::Focus($Handle) }
        FocusEditor = { param($Editor) $Editor.SetFocus() }
        AssertFocus = {
            param($Editor, $Handle)
            Assert-EditorFocus -Editor $Editor -WindowHandle $Handle
        }
        SetClipboardText = { param($Text) [System.Windows.Forms.Clipboard]::SetText($Text) }
        GetClipboardText = { [System.Windows.Forms.Clipboard]::GetText() }
        SendKeys = { param($Keys) [System.Windows.Forms.SendKeys]::SendWait($Keys) }
        Delay = { param($Milliseconds) Start-Sleep -Milliseconds $Milliseconds }
        IsEmptyEditor = {
            param($Editor)
            $pattern = $null
            if ($Editor.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$pattern)) {
                return $pattern.DocumentRange.GetText(-1) -ceq ''
            }
            return $false
        }
    }
}

function Copy-EditorText {
    param($Editor, [long]$WindowHandle, [hashtable]$Desktop)
    & $Desktop.AssertFocus $Editor $WindowHandle
    # Sentinel distinguishes empty/unsupported copy from stale clipboard contents.
    $sentinel = '__web_analyzer_' + [Guid]::NewGuid().ToString('N')
    & $Desktop.SetClipboardText $sentinel
    & $Desktop.SendKeys '^a'
    & $Desktop.AssertFocus $Editor $WindowHandle
    & $Desktop.SendKeys '^c'
    $copied = $sentinel
    for ($i = 0; $i -lt 20; $i++) {
        & $Desktop.Delay 50
        $copied = & $Desktop.GetClipboardText
        if ($copied -cne $sentinel) { break }
    }
    & $Desktop.AssertFocus $Editor $WindowHandle
    if ($copied -ceq $sentinel) {
        # Empty editors often leave the clipboard untouched. Confirm through UIA.
        if (& $Desktop.IsEmptyEditor $Editor) { return '' }
        throw 'Copy did not expose editor text. The editor may be unsupported; no write was attempted.'
    }
    return $copied
}

function Invoke-EditorTransfer {
    param(
        [string]$ExpectedUrl,
        [long]$ExpectedWindowHandle,
        [string]$EditorName,
        [AllowEmptyString()][string]$Code,
        [string]$ExpectedContentSha256,
        [switch]$Write,
        [hashtable]$Desktop
    )
    if ($null -eq $Desktop) { $Desktop = New-EditorDesktop }
    $page = & $Desktop.BindPage $ExpectedUrl $ExpectedWindowHandle
    $editor = & $Desktop.FindEditor $page.Document $EditorName
    $savedClipboard = & $Desktop.SnapshotClipboard
    $restored = $false
    $previous = $null
    $result = $null
    try {
        if (-not (& $Desktop.FocusWindow $ExpectedWindowHandle)) {
            throw 'Windows refused to focus the identified Chrome window.'
        }
        & $Desktop.FocusEditor $editor
        $previous = Copy-EditorText -Editor $editor -WindowHandle $ExpectedWindowHandle -Desktop $Desktop
        $previousHash = Get-ContentSha256 -Text $previous
        if ($Write) {
            if ($previousHash -cne $ExpectedContentSha256) {
                throw 'Editor content changed since capture. Read and review the current code before replacing it.'
            }
            $null = & $Desktop.BindPage $ExpectedUrl $ExpectedWindowHandle
            & $Desktop.AssertFocus $editor $ExpectedWindowHandle
            # Ctrl+A from capture still selects editor content. Paste preserves quotes and newlines.
            if ($Code.Length -eq 0) {
                & $Desktop.SendKeys '{BACKSPACE}'
            } else {
                & $Desktop.SetClipboardText $Code
                & $Desktop.SendKeys '^v'
            }
            & $Desktop.Delay 200
            $actual = Copy-EditorText -Editor $editor -WindowHandle $ExpectedWindowHandle -Desktop $Desktop
            if ((Get-ContentSha256 -Text $actual) -cne (Get-ContentSha256 -Text $Code)) {
                throw 'Editor readback differs from the intended code. Inspect the current editor before retrying; no execution was requested.'
            }
        } else { $actual = $previous }
        $null = & $Desktop.BindPage $ExpectedUrl $ExpectedWindowHandle
        & $Desktop.AssertFocus $editor $ExpectedWindowHandle
        & $Desktop.SendKeys '{RIGHT}'
        $result = [pscustomobject]@{
            Context = $page.Context
            EditorName = $EditorName
            Text = $actual
            PreviousText = $previous
            ContentSha256 = Get-ContentSha256 -Text $actual
            PreviousContentSha256 = $previousHash
            Written = [bool]$Write
            Verified = $true
            Executed = $false
            ClipboardRestored = $false
        }
    } finally {
        try {
            & $Desktop.RestoreClipboard $savedClipboard
            $restored = $true
        } catch {
            Write-Warning 'Could not restore the clipboard. The editor operation must not be retried automatically.'
        }
    }
    $result.ClipboardRestored = $restored
    return $result
}

function Get-BrowserEditor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ExpectedUrl,
        [Parameter(Mandatory)][long]$ExpectedWindowHandle,
        [Parameter(Mandatory)][string]$EditorName
    )
    Invoke-EditorTransfer @PSBoundParameters
}

function Set-BrowserEditor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ExpectedUrl,
        [Parameter(Mandatory)][long]$ExpectedWindowHandle,
        [Parameter(Mandatory)][string]$EditorName,
        [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedContentSha256,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Code
    )
    Invoke-EditorTransfer @PSBoundParameters -Write
}

function Test-CaptureImage {
    param([Parameter(Mandatory)]$Bitmap)
    $colors = New-Object 'System.Collections.Generic.HashSet[int]'
    for ($y = 0; $y -lt $Bitmap.Height; $y += [Math]::Max(1, [int]($Bitmap.Height / 40))) {
        for ($x = 0; $x -lt $Bitmap.Width; $x += [Math]::Max(1, [int]($Bitmap.Width / 40))) {
            $null = $colors.Add($Bitmap.GetPixel($x, $y).ToArgb())
        }
    }
    return $colors.Count -ge 2
}

function Get-BrowserPageImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ExpectedUrl,
        [Parameter(Mandatory)][long]$ExpectedWindowHandle
    )
    $page = Get-BoundPage @PSBoundParameters
    Add-Type -AssemblyName System.Drawing
    $bitmap = $null; $viewport = $null; $graphics = $null; $stream = $null
    # Use physical pixel bounds, restoring the calling thread's DPI context afterwards.
    $oldDpi = [WebAnalyzer.NativeDesktop]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
    try {
        if ($oldDpi -eq [IntPtr]::Zero) { throw 'Cannot establish physical-pixel capture coordinates.' }
        $rect = New-Object WebAnalyzer.NativeDesktop+WindowRect
        if (-not [WebAnalyzer.NativeDesktop]::GetWindowRect([IntPtr]$ExpectedWindowHandle, [ref]$rect)) {
            throw 'Cannot read Chrome window bounds.'
        }
        $width = $rect.Right - $rect.Left; $height = $rect.Bottom - $rect.Top
        if ($width -lt 16 -or $height -lt 16 -or ([long]$width * $height) -gt 40000000) {
            throw 'Invalid or oversized Chrome capture bounds.'
        }
        $bitmap = New-Object System.Drawing.Bitmap $width, $height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $dc = $graphics.GetHdc()
        try {
            # PW_RENDERFULLCONTENT captures Chrome itself, not the desktop/overlapping terminal.
            $captured = [WebAnalyzer.NativeDesktop]::PrintWindow([IntPtr]$ExpectedWindowHandle, $dc, 2)
        } finally { $graphics.ReleaseHdc($dc) }
        if (-not $captured) { throw 'Chrome did not provide a window image. No desktop fallback was used.' }
        # UIA bounds are physical screen pixels. Crop away tabs/address bar so their
        # varied colors cannot disguise an entirely black/blank page surface.
        $bounds = $page.Document.Current.BoundingRectangle
        $crop = [System.Drawing.Rectangle]::FromLTRB(
            [int][Math]::Ceiling($bounds.Left - $rect.Left), [int][Math]::Ceiling($bounds.Top - $rect.Top),
            [int][Math]::Floor($bounds.Right - $rect.Left), [int][Math]::Floor($bounds.Bottom - $rect.Top))
        if ($crop.Left -lt 0 -or $crop.Top -lt 0 -or $crop.Right -gt $width -or $crop.Bottom -gt $height -or
            $crop.Width -lt 16 -or $crop.Height -lt 16) { throw 'Page viewport does not fit the Chrome capture bounds.' }
        $viewport = $bitmap.Clone($crop, $bitmap.PixelFormat)
        if (-not (Test-CaptureImage -Bitmap $viewport)) { throw 'Chrome returned a blank/uniform page image. Visual evidence is unavailable.' }
        $afterPage = Get-BoundPage @PSBoundParameters
        if ($afterPage.Document.Current.BoundingRectangle -ne $bounds) {
            throw 'Page viewport changed during capture. Rediscover before retrying.'
        }
        $afterRect = New-Object WebAnalyzer.NativeDesktop+WindowRect
        if (-not [WebAnalyzer.NativeDesktop]::GetWindowRect([IntPtr]$ExpectedWindowHandle, [ref]$afterRect) -or
            $afterRect.Left -ne $rect.Left -or $afterRect.Top -ne $rect.Top -or
            $afterRect.Right -ne $rect.Right -or $afterRect.Bottom -ne $rect.Bottom) {
            throw 'Chrome window moved or resized during capture. Rediscover before retrying.'
        }
        $stream = New-Object IO.MemoryStream
        $viewport.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
        return [pscustomobject]@{
            Context = $page.Context
            CapturedAtUtc = [DateTime]::UtcNow.ToString('o')
            MimeType = 'image/png'; Width = $viewport.Width; Height = $viewport.Height
            Scope = 'PageViewport'; Method = 'PrintWindow'
            Data = [Convert]::ToBase64String($stream.ToArray())
        }
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $viewport) { $viewport.Dispose() }
        if ($null -ne $graphics) { $graphics.Dispose() }
        if ($null -ne $bitmap) { $bitmap.Dispose() }
        if ($oldDpi -ne [IntPtr]::Zero) { $null = [WebAnalyzer.NativeDesktop]::SetThreadDpiAwarenessContext($oldDpi) }
    }
}

Export-ModuleMember -Function Get-PrimaryBrowserContext, Read-BrowserPage, Get-BrowserPageImage, Get-BrowserEditor, Set-BrowserEditor, Select-PrimaryBrowserWindow, Assert-ExpectedContext, Get-ContentSha256
