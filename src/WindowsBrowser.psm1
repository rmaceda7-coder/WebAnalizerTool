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

function Copy-EditorText {
    param($Editor, [long]$WindowHandle)
    Assert-EditorFocus -Editor $Editor -WindowHandle $WindowHandle
    # Sentinel distinguishes empty/unsupported copy from stale clipboard contents.
    $sentinel = '__web_analyzer_' + [Guid]::NewGuid().ToString('N')
    [System.Windows.Forms.Clipboard]::SetText($sentinel)
    [System.Windows.Forms.SendKeys]::SendWait('^a')
    Assert-EditorFocus -Editor $Editor -WindowHandle $WindowHandle
    [System.Windows.Forms.SendKeys]::SendWait('^c')
    $copied = $sentinel
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 50
        $copied = [System.Windows.Forms.Clipboard]::GetText()
        if ($copied -cne $sentinel) { break }
    }
    Assert-EditorFocus -Editor $Editor -WindowHandle $WindowHandle
    if ($copied -ceq $sentinel) {
        # Empty editors often leave the clipboard untouched. Confirm through UIA.
        $pattern = $null
        if ($Editor.TryGetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern, [ref]$pattern)) {
            $rangeText = $pattern.DocumentRange.GetText(-1)
            if ($rangeText -ceq '') {
                return ''
            }
        }
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
        [switch]$Write
    )
    $page = Get-BoundPage -ExpectedUrl $ExpectedUrl -ExpectedWindowHandle $ExpectedWindowHandle
    $editor = Get-ExactEditor -Document $page.Document -EditorName $EditorName
    $oldClipboard = [System.Windows.Forms.Clipboard]::GetDataObject()
    # Materialize clipboard formats before changing focus or replacing the clipboard.
    $savedClipboard = New-Object System.Windows.Forms.DataObject
    if ($null -ne $oldClipboard) {
        foreach ($format in $oldClipboard.GetFormats($false)) {
            $savedClipboard.SetData($format, $oldClipboard.GetData($format, $false))
        }
    }
    $restored = $false
    $previous = $null
    $result = $null
    try {
        if (-not [WebAnalyzer.NativeDesktop]::Focus($ExpectedWindowHandle)) {
            throw 'Windows refused to focus the identified Chrome window.'
        }
        $editor.SetFocus()
        $previous = Copy-EditorText -Editor $editor -WindowHandle $ExpectedWindowHandle
        $previousHash = Get-ContentSha256 -Text $previous
        if ($Write) {
            if ($previousHash -cne $ExpectedContentSha256) {
                throw 'Editor content changed since capture. Read and review the current code before replacing it.'
            }
            $null = Get-BoundPage -ExpectedUrl $ExpectedUrl -ExpectedWindowHandle $ExpectedWindowHandle
            Assert-EditorFocus -Editor $editor -WindowHandle $ExpectedWindowHandle
            # Ctrl+A from capture still selects editor content. Paste preserves quotes and newlines.
            if ($Code.Length -eq 0) {
                [System.Windows.Forms.SendKeys]::SendWait('{BACKSPACE}')
            } else {
                [System.Windows.Forms.Clipboard]::SetText($Code)
                [System.Windows.Forms.SendKeys]::SendWait('^v')
            }
            Start-Sleep -Milliseconds 200
            $actual = Copy-EditorText -Editor $editor -WindowHandle $ExpectedWindowHandle
            if ((Get-ContentSha256 -Text $actual) -cne (Get-ContentSha256 -Text $Code)) {
                throw 'Editor readback differs from the intended code. Inspect the current editor before retrying; no execution was requested.'
            }
        } else { $actual = $previous }
        $null = Get-BoundPage -ExpectedUrl $ExpectedUrl -ExpectedWindowHandle $ExpectedWindowHandle
        Assert-EditorFocus -Editor $editor -WindowHandle $ExpectedWindowHandle
        [System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')
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
            if ($null -ne $oldClipboard -and $savedClipboard.GetFormats().Count -gt 0) {
                [System.Windows.Forms.Clipboard]::SetDataObject($savedClipboard, $true)
            } else { [System.Windows.Forms.Clipboard]::Clear() }
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

Export-ModuleMember -Function Get-PrimaryBrowserContext, Read-BrowserPage, Get-BrowserEditor, Set-BrowserEditor, Select-PrimaryBrowserWindow, Assert-ExpectedContext, Get-ContentSha256
