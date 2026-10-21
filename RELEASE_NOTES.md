# Android Bootloader Flasher v1.1.0

## Release Notes

### Overview
Android Bootloader Flasher is a Windows PowerShell utility for a generic ADB and Fastboot workflow. It does not implement vendor-specific flashing procedures such as Samsung Download Mode, Odin, or Heimdall.

### Included
- USB debugging setup wizard
- Device detection via ADB
- Generic Fastboot bootloader workflow
- Fail-closed unlock-status checks, serial matching, and typed flash confirmation
- Real-time activity log
- Windows installer support
- Safety and installation documentation
- Improved guidance and messaging for troubleshooting and support

### Requirements
- Windows 10/11
- Android Platform Tools (adb.exe and fastboot.exe)
- USB cable
- Correct bootloader image for the exact device model

### Important
Android still requires the user to manually enable Developer Options, turn on USB debugging, and approve the USB connection on the phone. This app can guide the user through that process, but it cannot bypass Android's permission model from the PC.

### Safety Warning
Bootloader flashing is risky and can permanently damage a phone if used incorrectly. Only use files intended for your exact device model and vendor. Do not disconnect the USB cable during flashing.

### Changelog for v1.1.0
- Improved device status and troubleshooting messaging
- Added portable ZIP packaging and Windows CI build validation
- Clarified standard Fastboot-only support and unsupported vendor-specific modes
- Clearer bootloader flash warnings and confirmation flow
- Improved log output for app support and issue triage
- Added version-tracking notes and release planning
- Updated documentation for version clarity and release readiness

### Installation
1. Download the installer or ZIP from GitHub Releases when a maintainer publishes them; the build script creates local artifacts only
2. Install Android Platform Tools if not already installed
3. Enable USB debugging on the phone
4. Approve the PC connection on the phone
5. Run the app

### Disclaimer
Use this tool entirely at your own risk. This is intended for advanced users who understand the risks of bootloader flashing.
