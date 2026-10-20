[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

$script:ADBPath = $null
$script:FastbootPath = $null
$script:SelectedImage = ""
$script:DeviceConnected = $false
$script:DeviceSerial = $null
$script:DeviceModel = "Unknown"

function Find-PlatformTools {
    $paths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
        "$env:ProgramFiles(x86)\Android\platform-tools",
        "$env:ProgramFiles\Android\platform-tools",
        "$PSScriptRoot\platform-tools"
    )

    foreach ($path in $paths) {
        if (Test-Path (Join-Path $path "adb.exe")) {
            $script:ADBPath = (Join-Path $path "adb.exe")
        }
        if (Test-Path (Join-Path $path "fastboot.exe")) {
            $script:FastbootPath = (Join-Path $path "fastboot.exe")
        }
    }

    if (-not $script:ADBPath) {
        $script:ADBPath = (Get-Command adb -ErrorAction SilentlyContinue).Source
    }
    if (-not $script:FastbootPath) {
        $script:FastbootPath = (Get-Command fastboot -ErrorAction SilentlyContinue).Source
    }

    if (-not $script:ADBPath -or -not $script:FastbootPath) {
        throw "ADB and Fastboot were not found. Install Android Platform Tools or place adb.exe and fastboot.exe in PATH."
    }
}

function Log-Message {
    param([string]$Message)
    $logBox.AppendText((Get-Date).ToString("HH:mm:ss") + " - " + $Message + "`r`n")
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.ScrollToCaret()
}

function UpdateStatus {
    param([string]$Text, [System.Drawing.Color]$Color)
    $statusLabel.Text = $Text
    $statusLabel.ForeColor = $Color
}

function Run-Command {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    $output = & $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = ($output | ForEach-Object { $_.ToString() }) -join "`r`n"
    }
}

function ShowUsbDebuggingWizard {
    $wizard = New-Object System.Windows.Forms.Form
    $wizard.Text = "Enable USB Debugging"
    $wizard.Size = New-Object System.Drawing.Size(720, 420)
    $wizard.StartPosition = "CenterScreen"
    $wizard.FormBorderStyle = "FixedSingle"
    $wizard.MaximizeBox = $false

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Step 1: Enable USB debugging on the Android phone"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $title.Location = New-Object System.Drawing.Point(20, 20)
    $title.Size = New-Object System.Drawing.Size(620, 40)

    $instructions = New-Object System.Windows.Forms.TextBox
    $instructions.Multiline = $true
    $instructions.ReadOnly = $true
    $instructions.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $instructions.Location = New-Object System.Drawing.Point(20, 70)
    $instructions.Size = New-Object System.Drawing.Size(650, 220)
    $instructions.Text = @"
1. On the Android phone, open Settings.
2. Tap About phone.
3. Tap Build number 7 times to enable Developer options.
4. Go back to Settings > Developer options.
5. Turn on USB debugging.
6. Connect the phone to the PC with a USB cable.
7. When prompted, tap Allow on the phone.
8. Return to this app and click Continue.

Important: Android requires the user to approve the PC connection before ADB can access the device.
"@

    $continueBtn = New-Object System.Windows.Forms.Button
    $continueBtn.Text = "Continue"
    $continueBtn.Location = New-Object System.Drawing.Point(500, 310)
    $continueBtn.Size = New-Object System.Drawing.Size(170, 40)
    $continueBtn.Add_Click({
        $wizard.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $wizard.Close()
    })

    $wizard.Controls.Add($title)
    $wizard.Controls.Add($instructions)
    $wizard.Controls.Add($continueBtn)
    $wizard.ShowDialog()
}

function CheckDevice {
    $result = Run-Command -FilePath $script:ADBPath -Arguments @("devices")
    $deviceLines = @()
    foreach ($line in ($result.Output -split '\r?\n')) {
        if ($line -match '^\s*\S+\s+device\s*$') {
            $deviceLines += $line.Trim()
        }
    }

    if ($result.ExitCode -eq 0 -and $deviceLines.Count -eq 1) {
        $serialMatch = [regex]::Match($deviceLines[0], '^\s*(\S+)\s+device\s*$')
        $script:DeviceSerial = $serialMatch.Groups[1].Value
        $modelResult = Run-Command -FilePath $script:ADBPath -Arguments @('-s', $script:DeviceSerial, 'shell', 'getprop', 'ro.product.model')
        $script:DeviceModel = $modelResult.Output.Trim()
        if (-not $script:DeviceModel) {
            $script:DeviceModel = 'Unknown'
        }

        $script:DeviceConnected = $true
        UpdateStatus 'Device connected' ([System.Drawing.Color]::DarkGreen)
        Log-Message ('Device detected. Serial: ' + $script:DeviceSerial)
        Log-Message ('Model reported by Android: ' + $script:DeviceModel)
        Log-Message $result.Output
    }
    else {
        $script:DeviceConnected = $false
        $script:DeviceSerial = $null
        $script:DeviceModel = 'Unknown'
        UpdateStatus 'No unique device detected' ([System.Drawing.Color]::DarkRed)
        if ($deviceLines.Count -gt 1) {
            Log-Message 'Connect exactly one authorized Android device before continuing.'
        }
        else {
            Log-Message 'No authorized device detected. Enable USB debugging and approve the connection on the phone.'
        }
        Log-Message $result.Output
    }
}

function GetFastbootSerials {
    $result = Run-Command -FilePath $script:FastbootPath -Arguments @('devices')
    $serials = @()
    foreach ($line in ($result.Output -split '\r?\n')) {
        $match = [regex]::Match($line, '^\s*(\S+)\s+fastboot\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($match.Success) {
            $serials += $match.Groups[1].Value
        }
    }
    return $serials
}

function RebootToBootloader {
    if (-not $script:DeviceConnected -or -not $script:DeviceSerial) {
        Log-Message 'No uniquely identified device. Click Check Device and connect exactly one authorized phone first.'
        return
    }

    Log-Message ('Rebooting device ' + $script:DeviceSerial + ' into bootloader...')
    $result = Run-Command -FilePath $script:ADBPath -Arguments @('-s', $script:DeviceSerial, 'reboot', 'bootloader')
    Log-Message $result.Output
    if ($result.ExitCode -ne 0) {
        Log-Message 'ADB could not reboot the selected device to bootloader mode.'
        return
    }

    Start-Sleep -Seconds 5
    $serials = @(GetFastbootSerials)
    if ($serials.Count -eq 1 -and $serials[0] -eq $script:DeviceSerial) {
        UpdateStatus 'In bootloader mode' ([System.Drawing.Color]::DarkOrange)
        Log-Message ('Fastboot device verified: ' + $serials[0])
    }
    else {
        UpdateStatus 'Fastboot device not verified' ([System.Drawing.Color]::DarkRed)
        Log-Message 'Expected exactly one Fastboot device with the same serial as the Android device. Flashing will remain blocked.'
        Log-Message ($serials -join ', ')
    }
}

function GetUnlockStatus {
    $result = Run-Command -FilePath $script:FastbootPath -Arguments @('-s', $script:DeviceSerial, 'getvar', 'unlocked')
    Log-Message $result.Output

    if ($result.ExitCode -eq 0 -and $result.Output -match '(?im)^\s*(?:\(bootloader\)\s*)?(?:device\s+)?unlocked:\s*(?:yes|true|1)\s*$') {
        Log-Message 'Fastboot positively reported that the bootloader is unlocked.'
        return $true
    }

    if ($result.Output -match '(?im)^\s*(?:\(bootloader\)\s*)?(?:device\s+)?unlocked:\s*(?:no|false|0)\s*$') {
        Log-Message 'Fastboot reported a locked bootloader. Flashing is blocked.'
    }
    else {
        Log-Message 'Could not positively verify that the bootloader is unlocked. Flashing is blocked.'
    }
    return $false
}

function ConfirmFlash {
    param(
        [string]$Serial,
        [string]$Model,
        [string]$ImagePath
    )

    $lineBreak = [Environment]::NewLine
    $expectedConfirmation = 'FLASH ' + $Serial
    $confirmationForm = New-Object System.Windows.Forms.Form
    $confirmationForm.Text = 'Confirm Bootloader Flash'
    $confirmationForm.Size = New-Object System.Drawing.Size(700, 360)
    $confirmationForm.StartPosition = 'CenterParent'
    $confirmationForm.FormBorderStyle = 'FixedDialog'
    $confirmationForm.MaximizeBox = $false
    $confirmationForm.MinimizeBox = $false

    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Location = New-Object System.Drawing.Point(20, 20)
    $warningLabel.Size = New-Object System.Drawing.Size(640, 155)
    $warningLabel.Text = ('Android-reported model (informational): ' + $Model + $lineBreak +
        'Fastboot serial: ' + $Serial + $lineBreak +
        'Image: ' + [System.IO.Path]::GetFileName($ImagePath) + $lineBreak + $lineBreak +
        'This app cannot verify that the image is compatible with this exact model. Check the device and image against official manufacturer guidance. An incompatible image can permanently damage the device.' + $lineBreak +
        'To continue, type exactly: ' + $expectedConfirmation)

    $confirmationInput = New-Object System.Windows.Forms.TextBox
    $confirmationInput.Name = 'confirmationInput'
    $confirmationInput.Location = New-Object System.Drawing.Point(20, 195)
    $confirmationInput.Size = New-Object System.Drawing.Size(440, 28)

    $confirmButton = New-Object System.Windows.Forms.Button
    $confirmButton.Text = 'Flash Bootloader'
    $confirmButton.Location = New-Object System.Drawing.Point(475, 192)
    $confirmButton.Size = New-Object System.Drawing.Size(165, 34)
    $confirmButton.Tag = $expectedConfirmation
    $confirmButton.Add_Click({
        $dialog = $this.FindForm()
        $entry = $dialog.Controls['confirmationInput']
        if ($entry.Text -ceq [string]$this.Tag) {
            $dialog.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $dialog.Close()
        }
        else {
            [void][System.Windows.Forms.MessageBox]::Show('The confirmation text did not match. No flash was started.', 'Confirmation required', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = New-Object System.Drawing.Point(475, 238)
    $cancelButton.Size = New-Object System.Drawing.Size(165, 34)
    $cancelButton.Add_Click({
        $dialog = $this.FindForm()
        $dialog.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $dialog.Close()
    })

    $confirmationForm.AcceptButton = $confirmButton
    $confirmationForm.CancelButton = $cancelButton
    $confirmationForm.Controls.Add($warningLabel)
    $confirmationForm.Controls.Add($confirmationInput)
    $confirmationForm.Controls.Add($confirmButton)
    $confirmationForm.Controls.Add($cancelButton)

    $result = $confirmationForm.ShowDialog($form)
    $confirmationForm.Dispose()
    return ($result -eq [System.Windows.Forms.DialogResult]::OK)
}

function SelectImage {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Bootloader images (*.img;*.bin)|*.img;*.bin"
    $dialog.Title = "Select Bootloader Image"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:SelectedImage = $dialog.FileName
        $imageBox.Text = $script:SelectedImage
        Log-Message "Selected bootloader image: $script:SelectedImage"
    }
}

function FlashBootloader {
    if (-not $script:DeviceConnected -or -not $script:DeviceSerial) {
        Log-Message 'No uniquely identified device. Click Check Device and connect exactly one authorized phone first.'
        return
    }

    if (-not $script:SelectedImage -or -not (Test-Path -LiteralPath $script:SelectedImage)) {
        Log-Message 'Please select a valid bootloader image before flashing.'
        return
    }

    $extension = [System.IO.Path]::GetExtension($script:SelectedImage).ToLowerInvariant()
    if ($extension -notin @('.img', '.bin')) {
        Log-Message 'Only .img and .bin image files are accepted.'
        return
    }

    $serials = @(GetFastbootSerials)
    if ($serials.Count -ne 1) {
        Log-Message 'Exactly one Fastboot device must be connected. Flashing is blocked.'
        return
    }

    $fastbootSerial = $serials[0]
    if ($fastbootSerial -ne $script:DeviceSerial) {
        Log-Message ('Fastboot serial does not match the checked Android device (' + $script:DeviceSerial + '). Flashing is blocked.')
        return
    }

    if (-not (GetUnlockStatus)) {
        return
    }

    if (-not (ConfirmFlash -Serial $fastbootSerial -Model $script:DeviceModel -ImagePath $script:SelectedImage)) {
        Log-Message 'Flash cancelled. No image was written.'
        return
    }

    $serials = @(GetFastbootSerials)
    if ($serials.Count -ne 1 -or $serials[0] -ne $fastbootSerial) {
        Log-Message 'Fastboot device changed or is ambiguous after confirmation. Flashing is blocked.'
        return
    }

    if (-not (GetUnlockStatus)) {
        return
    }

    Log-Message ('Flashing bootloader on device ' + $fastbootSerial + ': ' + $script:SelectedImage)
    $flashResult = Run-Command -FilePath $script:FastbootPath -Arguments @('-s', $fastbootSerial, 'flash', 'bootloader', $script:SelectedImage)
    Log-Message $flashResult.Output

    if ($flashResult.ExitCode -eq 0) {
        UpdateStatus 'Bootloader flash successful' ([System.Drawing.Color]::DarkGreen)
        Log-Message 'Bootloader flashed successfully.'
    }
    else {
        UpdateStatus 'Bootloader flash failed' ([System.Drawing.Color]::DarkRed)
        Log-Message 'Bootloader flash failed. Verify device compatibility, image, and unlock state.'
    }
}

function RebootSystem {
    if (-not $script:DeviceSerial) {
        Log-Message 'No checked device serial is available.'
        return
    }

    $serials = @(GetFastbootSerials)
    if ($serials.Count -ne 1 -or $serials[0] -ne $script:DeviceSerial) {
        Log-Message 'The checked device is not the only visible Fastboot device. Reboot was not sent.'
        return
    }

    $result = Run-Command -FilePath $script:FastbootPath -Arguments @('-s', $script:DeviceSerial, 'reboot')
    Log-Message $result.Output
    UpdateStatus 'Rebooting to system' ([System.Drawing.Color]::DarkOrange)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Android Bootloader Flasher"
$form.Width = 900
$form.Height = 620
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.StartPosition = "CenterScreen"

$title = New-Object System.Windows.Forms.Label
$title.Text = "Android Bootloader Flasher"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 20)
$title.Size = New-Object System.Drawing.Size(400, 35)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Waiting for setup"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$statusLabel.Location = New-Object System.Drawing.Point(20, 60)
$statusLabel.Size = New-Object System.Drawing.Size(280, 30)
$statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange

$selectBtn = New-Object System.Windows.Forms.Button
$selectBtn.Text = "Select Bootloader Image"
$selectBtn.Location = New-Object System.Drawing.Point(20, 110)
$selectBtn.Size = New-Object System.Drawing.Size(200, 40)
$selectBtn.Add_Click({ SelectImage })

$imageBox = New-Object System.Windows.Forms.TextBox
$imageBox.Location = New-Object System.Drawing.Point(240, 118)
$imageBox.Size = New-Object System.Drawing.Size(620, 25)
$imageBox.ReadOnly = $true
$imageBox.Text = "No image selected"

$checkBtn = New-Object System.Windows.Forms.Button
$checkBtn.Text = "Check Device"
$checkBtn.Location = New-Object System.Drawing.Point(20, 170)
$checkBtn.Size = New-Object System.Drawing.Size(150, 40)
$checkBtn.Add_Click({ CheckDevice })

$bootBtn = New-Object System.Windows.Forms.Button
$bootBtn.Text = "Reboot to Bootloader"
$bootBtn.Location = New-Object System.Drawing.Point(190, 170)
$bootBtn.Size = New-Object System.Drawing.Size(180, 40)
$bootBtn.Add_Click({ RebootToBootloader })

$flashBtn = New-Object System.Windows.Forms.Button
$flashBtn.Text = "Flash Bootloader"
$flashBtn.Location = New-Object System.Drawing.Point(390, 170)
$flashBtn.Size = New-Object System.Drawing.Size(180, 40)
$flashBtn.BackColor = [System.Drawing.Color]::LightCoral
$flashBtn.Add_Click({ FlashBootloader })

$rebootBtn = New-Object System.Windows.Forms.Button
$rebootBtn.Text = "Reboot to System"
$rebootBtn.Location = New-Object System.Drawing.Point(590, 170)
$rebootBtn.Size = New-Object System.Drawing.Size(180, 40)
$rebootBtn.Add_Click({ RebootSystem })

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(20, 240)
$logBox.Size = New-Object System.Drawing.Size(840, 260)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 10)

$warning = New-Object System.Windows.Forms.Label
$warning.Text = "Warning: only flash the correct image for your exact phone model. This can brick the device if done incorrectly."
$warning.Location = New-Object System.Drawing.Point(20, 510)
$warning.Size = New-Object System.Drawing.Size(840, 40)
$warning.ForeColor = [System.Drawing.Color]::DarkRed
$warning.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

$form.Controls.Add($title)
$form.Controls.Add($statusLabel)
$form.Controls.Add($selectBtn)
$form.Controls.Add($imageBox)
$form.Controls.Add($checkBtn)
$form.Controls.Add($bootBtn)
$form.Controls.Add($flashBtn)
$form.Controls.Add($rebootBtn)
$form.Controls.Add($logBox)
$form.Controls.Add($warning)

try {
    Find-PlatformTools
    Log-Message "ADB path: $script:ADBPath"
    Log-Message "Fastboot path: $script:FastbootPath"
    ShowUsbDebuggingWizard
    CheckDevice
} catch {
    Log-Message "Initialization error: $($_.Exception.Message)"
    UpdateStatus "Setup failed" ([System.Drawing.Color]::DarkRed)
}

$form.ShowDialog()
