# Android Bootloader Flasher v1.1.0 — Download and Install

## What this app supports

This is a Windows PowerShell/Windows Forms tool for a standard Android ADB and Fastboot workflow. It detects one authorized Android device, selects a bootloader image, reboots the device to Fastboot, checks that Fastboot positively reports an unlocked bootloader, and requires a typed serial confirmation before it attempts to flash the standard bootloader partition.

The app does not verify that an image matches a phone model. It does not implement Samsung Download Mode, Odin, Heimdall, or manufacturer-specific flashing procedures. Do not use it for devices whose manufacturer instructions require those workflows or a different partition layout.

## Requirements

- Windows 10 or 11 and Windows PowerShell 5.1
- Android SDK Platform Tools with adb.exe and fastboot.exe
- A USB cable and an Android device with Developer Options and USB debugging enabled
- The device must prompt you to authorize the connected PC; approve it on the phone
- A bootloader image verified for the exact device model and partition by the device manufacturer

The app searches the Android SDK platform-tools folder, common Android platform-tools folders, a platform-tools folder beside the app, and Windows PATH.

## Build the installer and portable ZIP

From the repository root, install Inno Setup and make sure iscc.exe is available on PATH. Then run:

~~~powershell
.\build-installer.ps1
~~~

The build creates these artifacts in the dist folder:

- AndroidBootloaderFlasherSetup.exe
- AndroidBootloaderFlasher-v1.1.0.zip

The ZIP places AndroidBootloaderFlasher.ps1 at its root. The build script creates artifacts locally; publishing them to GitHub Releases is a separate maintainer action.

## Run the app

1. Start the installer or extract the portable ZIP.
2. If using the ZIP, open PowerShell in the extracted folder and run:

~~~powershell
.\AndroidBootloaderFlasher.ps1
~~~

3. Enable Developer Options and USB debugging on the phone, connect it, and approve the PC on the phone.
4. Click Check Device. The app requires exactly one authorized device and shows the device serial and Android-reported model. The model is informational, not proof of image compatibility.
5. Select the image only after verifying it is for the exact device and standard bootloader partition. The picker accepts .img and .bin files.
6. Click Reboot to Bootloader. Before flashing, verify the Fastboot serial matches the checked Android device.
7. The app blocks the flash unless Fastboot positively reports the bootloader unlocked. Unknown or locked status is treated as unsafe and blocks flashing.
8. Review the confirmation dialog, verify the image again, and type the displayed FLASH serial text. Cancel if anything does not match.
9. After a successful flash, use Reboot to System.

A typed confirmation and an unlocked status do not prove the selected image is compatible. An incompatible image can permanently damage the device or cause data loss. Follow the device manufacturer's instructions and make a backup before proceeding.

## Troubleshooting

### ADB or Fastboot not found

Install the official Android SDK Platform Tools and add their folder to Windows PATH, or place the tools in a platform-tools folder beside the app. Restart PowerShell after changing PATH.

### No unique device detected

Connect one phone at a time, enable USB debugging, approve the authorization prompt on the phone, and click Check Device again. The app intentionally blocks when zero or multiple authorized Android devices are detected.

### Flashing is blocked because unlock status is unknown or locked

The app requires Fastboot to return a clear unlocked status. It will not continue when the device does not expose that status or reports locked. Follow the manufacturer's official device-specific instructions; do not bypass this check.

### Samsung or another vendor-specific mode

This app only supports the standard Fastboot bootloader partition. It does not control Samsung Download Mode, Odin, Heimdall, or other vendor-specific tools. Use the manufacturer's official workflow instead.

## Activity log

The Activity Log is shown in the app window and is not saved to an activity.log file by this version. Capture any useful messages before closing the app.

## Safety

- Verify the exact phone model, image, and partition using official manufacturer documentation.
- Back up important data; unlocking or flashing may erase it.
- Keep the phone charged and the USB cable connected throughout the operation.
- Do not use an image from an untrusted source.
- Stop if the device serial, reported model, image, or unlock status is unexpected.

Use this advanced tool at your own risk. The project is provided as-is.
