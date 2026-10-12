# Android Bootloader Flasher v1.0.0

## Release Notes

### Overview
Android Bootloader Flasher is a Windows-based utility for Android device workflows, with vendor-aware guidance for Motorola and Samsung devices.

### Included
- USB debugging setup wizard
- Device detection via ADB
- Motorola Fastboot workflow
- Samsung Download Mode guidance
- Generic Android bootloader support
- Real-time activity log
- Windows installer support
- Safety and installation documentation

### Requirements
- Windows 10/11
- Android Platform Tools (adb.exe and fastboot.exe)
- USB cable
- Correct bootloader image for the exact device model

### Important
Android still requires the user to manually enable Developer Options, turn on USB debugging, and approve the USB connection on the phone. This app can guide the user through that process, but it cannot bypass Android's permission model from the PC.

### Safety Warning
Bootloader flashing is risky and can permanently damage a phone if used incorrectly. Only use files intended for your exact device model and vendor. Do not disconnect the USB cable during flashing.

### Changelog
- Initial release
- Motorola-aware workflow
- Samsung Download Mode guidance
- USB debugging wizard
- ADB + Fastboot detection
- Bootloader image selection
- Activity log panel
- Installer build support

### Installation
1. Download the installer or ZIP package from the GitHub Release assets
2. Install Android Platform Tools if not already installed
3. Enable USB debugging on the phone
4. Approve the PC connection on the phone
5. Run the app

### Disclaimer
Use this tool entirely at your own risk. This is intended for advanced users who understand the risks of bootloader flashing.
