[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

$script:ADBPath = $null
$script:FastbootPath = $null
$script:SelectedImage = ""
$script:DeviceConnected = $false

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
    if ($result.Output -match "device\s*$") {
        $script:DeviceConnected = $true
        UpdateStatus "Device connected" ([System.Drawing.Color]::DarkGreen)
        Log-Message "Device detected."
        Log-Message $result.Output
    }
    else {
        $script:DeviceConnected = $false
        UpdateStatus "No device detected" ([System.Drawing.Color]::DarkRed)
        Log-Message "No device detected. Enable USB debugging and approve the connection on the phone."
        Log-Message $result.Output
    }
}

function RebootToBootloader {
    if (-not $script:DeviceConnected) {
        Log-Message "No device connected. Connect and authorize the phone first."
        return
    }

    Log-Message "Rebooting phone into bootloader..."
    $result = Run-Command -FilePath $script:ADBPath -Arguments @("reboot", "bootloader")
    Log-Message $result.Output
    Start-Sleep -Seconds 3

    $check = Run-Command -FilePath $script:FastbootPath -Arguments @("devices")
    if ($check.Output -match "fastboot") {
        UpdateStatus "In bootloader mode" ([System.Drawing.Color]::DarkOrange)
        Log-Message "Device is visible in fastboot."
    }
    else {
        Log-Message "Device is not yet visible in fastboot."
        Log-Message $check.Output
    }
}

function GetUnlockStatus {
    $result = Run-Command -FilePath $script:FastbootPath -Arguments @("getvar", "unlockability")
    Log-Message $result.Output

    if ($result.Output -match "unlocked") {
        Log-Message "Bootloader is unlocked."
    }
    elseif ($result.Output -match "locked") {
        Log-Message "Bootloader is locked. OEM unlock may be required."
    }
    else {
        Log-Message "Could not determine bootloader unlock status."
    }
}

function SelectImage {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Bootloader images (*.img;*.bin)|*.img;*.bin|All files (*.*)|*.*"
    $dialog.Title = "Select Bootloader Image"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:SelectedImage = $dialog.FileName
        $imageBox.Text = $script:SelectedImage
        Log-Message "Selected bootloader image: $script:SelectedImage"
    }
}

function FlashBootloader {
    if (-not $script:DeviceConnected) {
        Log-Message "No device connected. Connect and authorize the phone first."
        return
    }

    if (-not $script:SelectedImage -or -not (Test-Path $script:SelectedImage)) {
        Log-Message "Please select a valid bootloader image before flashing."
        return
    }

    $check = Run-Command -FilePath $script:FastbootPath -Arguments @("devices")
    if ($check.Output -notmatch "fastboot") {
        Log-Message "The device is not visible in fastboot. Reboot to bootloader mode first."
        return
    }

    GetUnlockStatus
    Log-Message "Flashing bootloader: $script:SelectedImage"

    $flashResult = Run-Command -FilePath $script:FastbootPath -Arguments @("flash", "bootloader", $script:SelectedImage)
    Log-Message $flashResult.Output

    if ($flashResult.ExitCode -eq 0) {
        UpdateStatus "Bootloader flash successful" ([System.Drawing.Color]::DarkGreen)
        Log-Message "Bootloader flashed successfully."
    }
    else {
        UpdateStatus "Bootloader flash failed" ([System.Drawing.Color]::DarkRed)
        Log-Message "Bootloader flash failed. Check the image, device model, and unlock state."
    }
}

function RebootSystem {
    $result = Run-Command -FilePath $script:FastbootPath -Arguments @("reboot")
    Log-Message $result.Output
    UpdateStatus "Rebooting to system" ([System.Drawing.Color]::DarkOrange)
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
