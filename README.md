# Android Bootloader Flasher

A Windows desktop application for flashing Android bootloaders using ADB and Fastboot.

## What this project does

- Shows a USB debugging setup wizard first
- Detects the Android device over ADB
- Lets the user select a bootloader image
- Reboots the device into bootloader mode
- Requires exactly one identified Android/Fastboot device
- Blocks flashing unless Fastboot positively reports an unlocked bootloader
- Requires typing the connected Fastboot serial to confirm a flash
- Flashes the selected bootloader image
- Reboots the device back to the OS

## Important limitation

This application cannot remotely enable USB debugging on the phone. Android requires the user to deliberately enable Developer Options and USB debugging on the device and approve the PC connection. The app helps the user do this with a guided first-run wizard. It supports the standard Fastboot bootloader partition only; it does not implement Samsung Download Mode, Odin, Heimdall, or vendor-specific flashing workflows.

## Requirements

- Windows 10/11
- Android SDK Platform Tools installed (`adb.exe`, `fastboot.exe`)
- USB cable
- Android device with Developer Options enabled
- Correct bootloader image for the exact phone model

## Run the app

```powershell
.\AndroidBootloaderFlasher.ps1
```

## Build the EXE installer

```powershell
.\build-installer.ps1
```

The installer is created with Inno Setup and output is placed in the `dist` folder.

## Safety warnings

- Only use bootloader images intended for your exact device model. The app cannot verify image-to-device compatibility; verify it using official manufacturer guidance.
- Some devices require OEM unlock and may wipe the phone.
- Do not unplug the phone during flashing.
- This is advanced flashing and can brick the device if used incorrectly.

## Disclaimer

Use at your own risk. This project is provided as-is and is intended for advanced users only.
