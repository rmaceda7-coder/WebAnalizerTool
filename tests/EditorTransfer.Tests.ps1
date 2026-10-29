# Dot-sourced by Run-Tests.ps1. Every desktop operation is replaced; no live UI is used.

function New-FakeEditorDesktop {
    param([AllowEmptyString()][string]$Text = 'SELECT 1;')
    $state = [pscustomobject]@{
        Text = $Text; Clipboard = 'original clipboard'; Focused = $false; Selected = $false
        Events = New-Object 'System.Collections.Generic.List[string]'
        Context = [pscustomobject]@{
            WindowHandle = 7; Url = 'https://example.test/editor'
            Monitor = [pscustomobject]@{ IsPrimary = $true }
        }
        BindCount = 0; ChangeAtBind = 0; AmbiguousEditor = $false
        SnapshotFails = $false; RestoreFails = $false; RestoreCount = 0
        FocusAllowed = $true; FocusEditorFails = $false; LoseFocusOnKey = ''
        ClipboardSetCount = 0; FailClipboardSetAt = 0; ClipboardReadFails = $false
        CopyCount = 0; UnsupportedCopy = $false; EmptyAccessible = $true
        BadReadback = $false; FailReadbackCopy = $false; FailPaste = $false
        CopyReadyAfterReads = 0; PendingCopy = $null; ReadsRemaining = 0
        ExpectedSnapshot = $null
    }
    $desktop = @{
        BindPage = {
            param($Url, $Handle)
            $state.Events.Add('BindPage'); $state.BindCount++
            if ($state.BindCount -eq $state.ChangeAtBind) { $state.Context.Url += '?changed' }
            Assert-ExpectedContext -Context $state.Context -ExpectedUrl $Url -ExpectedWindowHandle $Handle
            return [pscustomobject]@{ Context = $state.Context; Document = 'fake document' }
        }.GetNewClosure()
        FindEditor = {
            param($Document, $Name)
            $state.Events.Add('FindEditor')
            if ($Document -cne 'fake document' -or $Name -cne 'Disposable code editor') {
                throw 'Unexpected editor binding in test.'
            }
            if ($state.AmbiguousEditor) { throw 'Expected one visible editor; found 2.' }
            return 'fake editor'
        }.GetNewClosure()
        SnapshotClipboard = {
            $state.Events.Add('SnapshotClipboard')
            if ($state.SnapshotFails) { throw 'Simulated clipboard snapshot failure.' }
            $state.ExpectedSnapshot = [pscustomobject]@{ Text = $state.Clipboard }
            return $state.ExpectedSnapshot
        }.GetNewClosure()
        RestoreClipboard = {
            param($Snapshot)
            $state.Events.Add('RestoreClipboard'); $state.RestoreCount++
            if (-not [object]::ReferenceEquals($Snapshot, $state.ExpectedSnapshot)) {
                throw 'The captured clipboard snapshot was not preserved.'
            }
            if ($state.RestoreFails) { throw 'Simulated clipboard restore failure.' }
            $state.Clipboard = $Snapshot.Text
        }.GetNewClosure()
        FocusWindow = {
            param($Handle)
            $state.Events.Add('FocusWindow')
            if ($Handle -ne 7) { throw 'Unexpected window handle in test.' }
            return $state.FocusAllowed
        }.GetNewClosure()
        FocusEditor = {
            param($Editor)
            $state.Events.Add('FocusEditor')
            if ($state.FocusEditorFails) { throw 'Simulated editor focus failure.' }
            $state.Focused = $true
        }.GetNewClosure()
        AssertFocus = {
            param($Editor, $Handle)
            $state.Events.Add('AssertFocus')
            if ($Editor -cne 'fake editor' -or $Handle -ne 7 -or -not $state.Focused) {
                throw 'The target editor does not have keyboard focus.'
            }
        }.GetNewClosure()
        SetClipboardText = {
            param($Text)
            $state.Events.Add('SetClipboardText'); $state.ClipboardSetCount++
            if ($state.ClipboardSetCount -eq $state.FailClipboardSetAt) {
                throw 'Simulated clipboard set failure.'
            }
            $state.Clipboard = $Text
        }.GetNewClosure()
        GetClipboardText = {
            $state.Events.Add('GetClipboardText')
            if ($state.ClipboardReadFails) { throw 'Simulated clipboard read failure.' }
            if ($null -ne $state.PendingCopy) {
                $state.ReadsRemaining--
                if ($state.ReadsRemaining -le 0) {
                    $state.Clipboard = $state.PendingCopy; $state.PendingCopy = $null
                }
            }
            return $state.Clipboard
        }.GetNewClosure()
        SendKeys = {
            param($Keys)
            $state.Events.Add("Key:$Keys")
            switch ($Keys) {
                '^a' { $state.Selected = $true }
                '^c' {
                    if (-not $state.Selected) { throw 'Copy requires selected editor text in test.' }
                    $state.CopyCount++
                    if (-not $state.UnsupportedCopy -and $state.Text.Length -gt 0 -and
                        -not ($state.FailReadbackCopy -and $state.CopyCount -gt 1)) {
                        $text = $state.Text
                        if ($state.BadReadback -and $state.CopyCount -gt 1) { $text = 'corrupted readback' }
                        if ($state.CopyReadyAfterReads -gt 0) {
                            $state.PendingCopy = $text; $state.ReadsRemaining = $state.CopyReadyAfterReads
                        } else { $state.Clipboard = $text }
                    }
                }
                '^v' {
                    if ($state.FailPaste) { throw 'Simulated paste failure.' }
                    if ($state.Selected) { $state.Text = $state.Clipboard }
                    else { $state.Text += $state.Clipboard }
                    $state.Selected = $false
                }
                '{BACKSPACE}' {
                    if (-not $state.Selected) { throw 'Deletion requires selected editor text in test.' }
                    $state.Text = ''; $state.Selected = $false
                }
                '{RIGHT}' { $state.Selected = $false }
                default { throw "Unexpected key sequence: $Keys" }
            }
            if ($Keys -ceq $state.LoseFocusOnKey) { $state.Focused = $false }
        }.GetNewClosure()
        Delay = { param($Milliseconds) }.GetNewClosure()
        IsEmptyEditor = {
            param($Editor)
            $state.Events.Add('IsEmptyEditor')
            return $state.EmptyAccessible -and $state.Text.Length -eq 0
        }.GetNewClosure()
    }
    return [pscustomobject]@{ State = $state; Desktop = $desktop }
}

function Invoke-FakeEditorTransfer {
    param($Fake, [switch]$Write, [AllowEmptyString()][string]$Code = 'SELECT 2;',
        [string]$ExpectedHash = (Get-ContentSha256 -Text $Fake.State.Text))
    $parameters = @{
        ExpectedUrl = 'https://example.test/editor'; ExpectedWindowHandle = 7
        EditorName = 'Disposable code editor'; Code = $Code
        ExpectedContentSha256 = $ExpectedHash; Write = $Write
    }
    & (Get-Module WindowsBrowser) {
        param($Desktop, $Parameters)
        Invoke-EditorTransfer @Parameters -Desktop $Desktop
    } $Fake.Desktop $parameters
}

function Assert-TransferFailure {
    param($Fake, [string]$Pattern, [string]$Message,
        [AllowEmptyString()][string]$Code = 'SELECT 2;',
        [string]$ExpectedHash = (Get-ContentSha256 -Text $Fake.State.Text))
    $failure = $null
    try { $null = Invoke-FakeEditorTransfer -Fake $Fake -Write -Code $Code -ExpectedHash $ExpectedHash }
    catch { $failure = $_ }
    Assert-True ($null -ne $failure -and $failure.Exception.Message -match $Pattern) $Message
}

function Assert-ClipboardRestored {
    param($Fake, [string]$Message)
    Assert-True ($Fake.State.RestoreCount -eq 1 -and $Fake.State.Clipboard -ceq 'original clipboard') $Message
}

$fake = New-FakeEditorDesktop
$result = Invoke-FakeEditorTransfer -Fake $fake
Assert-True ($result.Text -ceq 'SELECT 1;' -and $result.PreviousText -ceq 'SELECT 1;') 'Capture returns the actual existing code'
Assert-True (-not $result.Written -and $result.Verified -and -not $result.Executed) 'Capture is verified without writing or executing'
Assert-True ($fake.State.Text -ceq 'SELECT 1;' -and $fake.State.Events -notcontains 'Key:^v') 'Capture does not paste or change editor text'
Assert-ClipboardRestored $fake 'Capture restores its original clipboard snapshot exactly once'

$fake = New-FakeEditorDesktop
$unicode = "SELECT 'caf$([char]0xE9)', '$([char]0x6F22)$([char]0x5B57)', '[quoted]';`r`nSELECT 2;"
$result = Invoke-FakeEditorTransfer -Fake $fake -Write -Code $unicode
Assert-True ($fake.State.Text -ceq $unicode -and $result.Text -ceq $unicode) 'Replacement preserves Unicode, quotes, brackets and newlines'
Assert-True ($result.PreviousText -ceq 'SELECT 1;' -and $result.PreviousContentSha256 -ceq (Get-ContentSha256 'SELECT 1;')) 'Replacement retains the captured previous code and fingerprint'
Assert-True ($result.Written -and $result.Verified -and -not $result.Executed -and $result.ClipboardRestored) 'Replacement reports verified, unexecuted success'
Assert-True (@($fake.State.Events | Where-Object { $_ -ceq 'Key:^v' }).Count -eq 1) 'Replacement pastes exactly once'
Assert-ClipboardRestored $fake 'Replacement restores its original clipboard snapshot'

$fake = New-FakeEditorDesktop
Assert-TransferFailure $fake 'content changed since capture' 'Stale content fingerprint blocks replacement' -ExpectedHash (Get-ContentSha256 'older code')
Assert-True ($fake.State.Text -ceq 'SELECT 1;' -and $fake.State.Events -notcontains 'Key:^v') 'Stale content is not overwritten'
Assert-ClipboardRestored $fake 'Fingerprint rejection still restores clipboard'

foreach ($bind in @(1, 2, 3)) {
    $fake = New-FakeEditorDesktop
    $fake.State.ChangeAtBind = $bind
    Assert-TransferFailure $fake 'Browser context changed' "Context change at binding $bind rejects the transfer"
    if ($bind -eq 1) {
        Assert-True ($fake.State.Events -notcontains 'SnapshotClipboard' -and $fake.State.Events -notcontains 'FocusWindow') 'Initial stale context does not access clipboard or focus'
    } else {
        Assert-ClipboardRestored $fake "Context change at binding $bind restores clipboard"
        Assert-True ($fake.State.Events -notcontains 'Key:{RIGHT}') "Context change at binding $bind sends no final selection key"
    }
    if ($bind -le 2) {
        Assert-True ($fake.State.Events -notcontains 'Key:^v') "Context change at binding $bind prevents paste"
    } else {
        Assert-True ($fake.State.Text -ceq 'SELECT 2;') 'Post-write context failure does not blindly roll back editor text'
    }
}

$fake = New-FakeEditorDesktop
$fake.State.AmbiguousEditor = $true
Assert-TransferFailure $fake 'found 2' 'Ambiguous editors are rejected'
Assert-True ($fake.State.Events -notcontains 'SnapshotClipboard' -and $fake.State.Events -notcontains 'FocusWindow') 'Ambiguous editor rejection precedes clipboard and focus access'

$fake = New-FakeEditorDesktop
$fake.State.SnapshotFails = $true
Assert-TransferFailure $fake 'snapshot failure' 'Clipboard snapshot failure aborts before focus or input'
Assert-True ($fake.State.Events -notcontains 'FocusWindow' -and $fake.State.RestoreCount -eq 0) 'Failed snapshot does not focus or attempt restoration from missing data'

$fake = New-FakeEditorDesktop
$fake.State.FocusAllowed = $false
Assert-TransferFailure $fake 'refused to focus' 'Refused window focus aborts the transfer'
Assert-True ($fake.State.Events -notcontains 'FocusEditor' -and $fake.State.ClipboardSetCount -eq 0) 'Refused focus sends no editor or clipboard input'
Assert-ClipboardRestored $fake 'Refused focus restores clipboard'

$fake = New-FakeEditorDesktop
$fake.State.FocusEditorFails = $true
Assert-TransferFailure $fake 'editor focus failure' 'Editor focus failure aborts the transfer'
Assert-ClipboardRestored $fake 'Editor focus failure restores clipboard'

foreach ($key in @('^a', '^c', '^v')) {
    $fake = New-FakeEditorDesktop
    $fake.State.LoseFocusOnKey = $key
    Assert-TransferFailure $fake 'does not have keyboard focus' "Focus loss after $key stops at the next guard"
    $index = $fake.State.Events.IndexOf("Key:$key")
    $laterKeys = @($fake.State.Events | Select-Object -Skip ($index + 1) | Where-Object { $_ -like 'Key:*' })
    Assert-True ($laterKeys.Count -eq 0) "No more keys are sent after focus loss on $key"
    Assert-ClipboardRestored $fake "Focus loss after $key restores clipboard"
}

foreach ($setAt in @(1, 2, 3)) {
    $fake = New-FakeEditorDesktop
    $fake.State.FailClipboardSetAt = $setAt
    Assert-TransferFailure $fake 'clipboard set failure' "Clipboard set failure $setAt aborts without retry"
    Assert-True ($fake.State.ClipboardSetCount -eq $setAt) "Clipboard set $setAt is not blindly retried"
    Assert-ClipboardRestored $fake "Clipboard set failure $setAt restores snapshot"
}

$fake = New-FakeEditorDesktop
$fake.State.ClipboardReadFails = $true
Assert-TransferFailure $fake 'clipboard read failure' 'Clipboard read failure aborts before replacement'
Assert-True ($fake.State.Events -notcontains 'Key:^v') 'Clipboard read failure does not paste'
Assert-ClipboardRestored $fake 'Clipboard read failure restores snapshot'

$fake = New-FakeEditorDesktop
$fake.State.UnsupportedCopy = $true
Assert-TransferFailure $fake 'Copy did not expose editor text' 'Unsupported copy is not mistaken for blank code'
Assert-True ($fake.State.Text -ceq 'SELECT 1;' -and $fake.State.Events -notcontains 'Key:^v') 'Unsupported nonempty editor is preserved'
Assert-True (@($fake.State.Events | Where-Object { $_ -ceq 'GetClipboardText' }).Count -eq 20) 'Unchanged clipboard polling stops at its bound'
Assert-ClipboardRestored $fake 'Unsupported copy restores snapshot'

$fake = New-FakeEditorDesktop -Text ''
$fake.State.EmptyAccessible = $false
Assert-TransferFailure $fake 'Copy did not expose editor text' 'Unconfirmed empty editor is rejected'
Assert-True ($fake.State.Events -notcontains 'Key:^v') 'Unconfirmed empty editor is not overwritten'
Assert-ClipboardRestored $fake 'Unconfirmed empty editor restores snapshot'

$fake = New-FakeEditorDesktop -Text ''
$result = Invoke-FakeEditorTransfer -Fake $fake -Write
Assert-True ($result.PreviousText -ceq '' -and $result.Text -ceq 'SELECT 2;' -and $result.Verified) 'Accessibility-confirmed empty editor can be replaced'
Assert-ClipboardRestored $fake 'Confirmed empty editor restores snapshot'

$fake = New-FakeEditorDesktop
$result = Invoke-FakeEditorTransfer -Fake $fake -Write -Code ''
Assert-True ($fake.State.Text -ceq '' -and $result.Text -ceq '' -and $result.Verified) 'Empty replacement is read back and verified'
Assert-True ($fake.State.Events -contains 'Key:{BACKSPACE}' -and $fake.State.Events -notcontains 'Key:^v') 'Empty replacement uses deletion rather than pasting stale clipboard'
Assert-ClipboardRestored $fake 'Empty replacement restores snapshot'

$fake = New-FakeEditorDesktop
$fake.State.CopyReadyAfterReads = 3
$result = Invoke-FakeEditorTransfer -Fake $fake -Write
Assert-True ($result.Verified -and $fake.State.CopyCount -eq 2) 'Delayed clipboard copy is polled without resending copy or paste'
Assert-ClipboardRestored $fake 'Delayed clipboard transfer restores snapshot'

$fake = New-FakeEditorDesktop
$fake.State.FailPaste = $true
Assert-TransferFailure $fake 'paste failure' 'Paste failure is propagated without retry'
Assert-True (@($fake.State.Events | Where-Object { $_ -ceq 'Key:^v' }).Count -eq 1) 'Failed paste is attempted only once'
Assert-ClipboardRestored $fake 'Paste failure restores snapshot'

$fake = New-FakeEditorDesktop
$fake.State.BadReadback = $true
Assert-TransferFailure $fake 'readback differs' 'Readback mismatch is never reported as verified success'
Assert-True ($fake.State.Text -ceq 'SELECT 2;' -and $fake.State.Events -notcontains 'Key:{RIGHT}') 'Readback mismatch leaves actual editor for inspection without rollback'
Assert-ClipboardRestored $fake 'Readback mismatch restores snapshot'

$fake = New-FakeEditorDesktop
$fake.State.FailReadbackCopy = $true
Assert-TransferFailure $fake 'Copy did not expose editor text' 'Unsupported post-write copy fails instead of trusting paste'
Assert-True ($fake.State.Text -ceq 'SELECT 2;') 'Failed post-write copy does not overwrite the new code again'
Assert-ClipboardRestored $fake 'Failed post-write copy restores snapshot'

$fake = New-FakeEditorDesktop
$fake.State.RestoreFails = $true
$records = @(Invoke-FakeEditorTransfer -Fake $fake -Write 3>&1)
$warnings = @($records | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
$results = @($records | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] })
Assert-True ($warnings.Count -eq 1 -and $warnings[0].Message -match 'Could not restore the clipboard') 'Clipboard restoration failure emits a warning'
Assert-True ($results.Count -eq 1 -and $results[0].Verified -and -not $results[0].ClipboardRestored) 'Restoration failure is distinguished from verified editor text'
Assert-True ($fake.State.RestoreCount -eq 1) 'Clipboard restoration is not blindly retried'

$fake = New-FakeEditorDesktop
$fake.State.BadReadback = $true; $fake.State.RestoreFails = $true
$outcome = [pscustomobject]@{ Failure = $null }
$warnings = @(& {
    try { $null = Invoke-FakeEditorTransfer -Fake $fake -Write }
    catch { $outcome.Failure = $_ }
} 3>&1)
Assert-True ($outcome.Failure.Exception.Message -match 'readback differs') 'Restoration failure does not mask the original transfer error'
Assert-True ($warnings.Count -eq 1 -and $fake.State.RestoreCount -eq 1) 'Failed transfer still reports its one failed restoration attempt'
