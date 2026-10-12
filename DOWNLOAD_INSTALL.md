# Release v1.0.0 - Download and Install Guide

## Download

Choose one of the download options below:

**Option A: Windows Installer (Recommended)**
- File: `AndroidBootloaderFlasherSetup.exe`
- Size: ~500 KB (after download and extraction)
- Installation: Standard Windows installer
- Best for: Users who want a traditional installation

**Option B: Portable ZIP Package**
- File: `AndroidBootloaderFlasher-v1.0.0.zip`
- Size: ~200 KB
- Installation: Extract and run
- Best for: Users who want portable/no-install option

## Quick Install

### Using the EXE Installer

1. Download `AndroidBootloaderFlasherSetup.exe`
2. Double-click to run
3. Click "Next" through the installer
4. Click "Install"
5. Check "Launch Android Bootloader Flasher"
6. Click "Finish"

The app will start immediately and show the USB debugging setup wizard.

### Using the ZIP Package

1. Download `AndroidBootloaderFlasher-v1.0.0.zip`
2. Right-click and select "Extract All"
3. Choose a folder (e.g., `C:\Tools\`)
4. Open PowerShell in the extracted folder
5. Run:
   ```powershell
   .\src\AndroidBootloaderFlasher.ps1
   ```

## System Requirements

- **OS:** Windows 10 or Windows 11
- **RAM:** 2 GB minimum
- **Disk:** 100 MB free space
- **Architecture:** 64-bit
- **Admin rights:** Required for installation

## Required Software

### Android Platform Tools (ADB + Fastboot)

**Download from:** https://developer.android.com/tools/releases/platform-tools

**Installation methods:**

**Method 1: Android Studio (Recommended)**
1. Download Android Studio from https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio
4. Go to Tools > SDK Manager
5. Select "SDK Tools" tab
6. Check "Android SDK Platform-Tools"
7. Click "OK" to install
8. Platform Tools are installed to:
   ```
   C:\Users\[YourUsername]\AppData\Local\Android\Sdk\platform-tools
   ```

**Method 2: Standalone Download**
1. Download from https://developer.android.com/tools/releases/platform-tools
2. Extract to a folder (e.g., `C:\Android\platform-tools`)
3. Add to Windows PATH:
   - Open Settings > System > About
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "User variables", click "New"
   - Variable name: `PATH`
   - Variable value: `C:\Android\platform-tools`
   - Click "OK"
4. Open a new PowerShell window
5. Test: Run `adb version`

**Method 3: Windows 11 Package Manager**
```powershell
winget install Google.AndroidSDKPlatformTools
```

## Device Preparation

Before using the app, enable USB debugging on your phone:

### Android 4.2 and later

1. Open Settings on the phone
2. Go to About phone
3. Tap "Build number" 7 times
   - You'll see a message: "You are now a developer"
4. Go back to Settings
5. Find Developer options (usually near the bottom)
6. Turn on "USB debugging"
7. Connect the phone to the PC with a USB cable
8. On the phone, a dialog will appear asking to allow the PC
9. Tap "Allow"
10. The phone is now authorized

### Motorola-specific
- Developer Options may be in a different location
- Fastboot entry is usually via ADB reboot
- Some models require bootloader unlock via Motorola support

### Samsung-specific
- Developer Options location varies by model and Android version
- Most models use Download Mode (Volume Down + Power + USB cable)
- Do NOT use generic Fastboot on Samsung devices
- Use Odin or Heimdall for flashing

## First Launch

When you run the app for the first time:

1. A USB debugging wizard window appears
2. It shows step-by-step instructions
3. Follow the on-screen guidance
4. Click "Continue" when you've enabled USB debugging
5. The main app window opens
6. If successful: "Device connected" appears in green
7. If failed: "No device detected" appears in red

## Selecting a Bootloader Image

1. Click "Select Image"
2. Browse to your bootloader file
3. Supported formats: `.img`, `.bin`
4. The file path appears in the text box
5. The log shows: "Selected image: [path]"

## Flashing Workflow

### For Motorola:

1. Select vendor: **Motorola**
2. Click **Check Device** (should show green "Device connected")
3. Select your bootloader image
4. Click **Bootloader** (phone enters Fastboot)
5. Wait 5 seconds
6. Click **Flash** (flashing begins)
7. Watch the log for success/failure
8. Click **Reboot** (phone reboots to system)

### For Samsung:

1. Select vendor: **Samsung**
2. Click **Check Device** (should show green "Device connected")
3. Click **Bootloader** (phone enters Download Mode)
4. Disconnect the phone
5. Use Odin or Heimdall (download these separately)
6. Flash the bootloader using the Samsung tool
7. Follow Samsung's official instructions

### For Generic Android:

1. Select vendor: **Generic**
2. Click **Check Device**
3. Select bootloader image
4. Click **Bootloader**
5. Click **Flash**
6. Click **Reboot**

## Monitoring Progress

The Activity Log shows:

- ✓ Green text = success
- ✗ Red text = error
- ⚠️ Orange text = warning
- White text = info

Example log:
```
[14:35:22] [SUCCESS] ADB: C:\...\adb.exe
[14:35:22] [SUCCESS] Fastboot: C:\...\fastboot.exe
[14:35:30] [SUCCESS] ADB device detected.
[14:35:35] [INFO] Rebooting Motorola to Fastboot...
[14:35:40] [SUCCESS] Device visible in Fastboot.
[14:35:45] [INFO] Flashing image: C:\bootloader.img
[14:35:50] [SUCCESS] Bootloader flashed successfully.
```

## Troubleshooting

### Issue: "No device detected"

**Solutions:**
1. Verify USB debugging is enabled:
   - Settings > Developer options > USB debugging: ON
2. Verify phone is authorized:
   - Disconnect and reconnect cable
   - Accept "Allow" prompt on phone again
3. Try a different USB port (not a USB hub)
4. Try a different USB cable
5. Install correct ADB drivers for your device:
   - Motorola: https://motorolasupport.com
   - Samsung: https://www.samsung.com/us/support/
   - Google Pixel: https://developer.android.com/studio/run/win-usb

### Issue: "ADB and Fastboot were not found"

**Solutions:**
1. Install Android Platform Tools (see above)
2. Add platform-tools to PATH
3. Or place adb.exe and fastboot.exe in:
   - `C:\program files\android\platform-tools`
   - Or next to the app folder
4. Restart PowerShell or command prompt after adding to PATH

### Issue: "Device not visible in Fastboot"

**Solutions:**
1. Try clicking "Bootloader" again
2. Wait 10 seconds (some phones take time)
3. Check device manufacturer's bootloader entry method
4. Some Motorola models need special key combination
5. Some Samsung models use Download Mode (not Fastboot)

### Issue: "Flash failed"

**Solutions:**
1. Verify the bootloader image is for your EXACT model
2. Check the log file for detailed error message
3. Verify bootloader is unlocked (OEM unlock in Dev Options)
4. Try flashing again
5. Check device manufacturer's documentation

### Issue: Samsung device not working

**Important:** Most Samsung devices do NOT use generic Fastboot.

**Correct method:**
1. Download Samsung firmware from https://samsung-com or https://sammobile.com
2. Download Odin from https://samsungodin.com or Heimdall
3. Put phone in Download Mode:
   - Power off phone
   - Hold Volume Down + Power + USB cable (simultaneously)
4. Connect to PC
5. Open Odin
6. Select the bootloader file
7. Click "Start" to flash
8. Wait for completion

## Getting Help

1. Check the Activity Log:
   - Look for red (ERROR) or orange (WARN) messages
   - Copy the relevant lines

2. Find your log file:
   ```
   %LOCALAPPDATA%\AndroidBootloaderFlasher\activity.log
   ```

3. Open an issue on GitHub with:
   - Device model (exact name)
   - Error message from the log
   - Windows version (10 or 11)
   - Steps you took before the error

## Uninstalling

### If you used the EXE installer:

1. Go to Settings > Apps > Apps & features
2. Find "Android Bootloader Flasher"
3. Click "Uninstall"
4. Follow the uninstall wizard

### If you used the ZIP package:

1. Delete the extracted folder
2. No cleanup needed

## Safety Reminders

⚠️ **Before you flash:**

1. **Backup everything:**
   - Phone data
   - Photos and videos
   - Contacts and messages
   - Everything may be lost

2. **Use the correct file:**
   - Download bootloader for YOUR EXACT model
   - Wrong file can brick the phone
   - Double-check the filename and model number

3. **Full battery:**
   - Charge to 100% before starting
   - Do not charge during flashing
   - Power loss can brick the device

4. **Don't interrupt:**
   - Never disconnect USB during flashing
   - Never close the app
   - Never turn off the phone
   - Process takes 2-5 minutes usually

5. **Know your device:**
   - Motorola: Standard Fastboot
   - Samsung: Download Mode + Odin/Heimdall
   - Others: Research your manufacturer's process

## Technical Notes

- **Log storage:** `%LOCALAPPDATA%\AndroidBootloaderFlasher\activity.log`
- **Runs on:** Windows 10/11 (64-bit only)
- **Framework:** PowerShell 5.0+ with Windows Forms
- **Requires:** Admin rights
- **No internet needed:** Works entirely offline
- **ADB protocol:** Android Debug Bridge
- **Fastboot:** Android bootloader flashing protocol

## Support

**Documentation:**
- README.md - Overview
- INSTALL.md - Detailed installation
- SAFETY.md - Safety guidelines
- CHANGELOG.md - Version history

**Issues:**
- GitHub Issues: Report bugs and request features
- Include device model, Windows version, and log contents

**License:**
- MIT License - Free for personal and commercial use

## Disclaimer

**Use this application entirely at your own risk.**

Bootloader flashing can:
- Permanently damage your device
- Void your warranty
- Cause data loss
- Brick the phone if done incorrectly

The developer is NOT responsible for:
- Bricked devices
- Data loss
- Warranty voiding
- Any damage or consequences from using this tool

This is an advanced tool for users who understand the risks and consequences.
