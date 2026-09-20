# Legichain KYC example / KYC örnek uygulaması

A runnable host application for the native Legichain v2 flow. Enter a Legichain
API token, choose Turkish or English, select whether NFC is required, and start.
The SDK makes the KYC requests directly from the phone. Package-registry tokens
(npm, NuGet or Maven) are not Legichain API tokens.

The example returns to its own screen when the native flow is submitted or
cancelled. Submission is not an approval; final verification arrives through
the account's configured webhook. The integrating company sends the applicant
its own notification after handling that webhook.

## Android

Use an NFC-capable Android phone (API 24+) for chip acceptance tests. The emulator
can check layouts but cannot validate a document chip.

```sh
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

The Android host already includes the activity manifest, CameraX/ML Kit/OpenCV
native dependencies and the packaging exclusion documented in the SDK guide.
Use Java 17+, Android SDK 35 and the Gradle/NDK versions selected by this project.

## iPhone

Build on a Mac with Xcode and CocoaPods. Connect the iPhone, trust the Mac, enable
Developer Mode if Xcode requests it, and select the phone as the target.

```sh
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

In Runner's Signing & Capabilities choose your Apple development team and a
unique bundle identifier. Provision the Near Field Communication Tag Reading
capability. Camera/NFC usage strings (TR/EN), ISO7816 AID and TAG entitlements
are already included in the example. Run the app on the physical phone;
iOS simulators cannot validate NFC. This repository has not yet been built or
accepted with Xcode or a physical iPhone.

## Acceptance / Kabul

Use a test account and check front/back document capture, MRZ inside the guide,
BAC/PACE chip reading, the five requested liveness actions, early movements,
interruption/retry, language selection and return to the host screen. Verify
the final application outcome independently from the signed webhook.

The iOS reader currently supports MRZ-based BAC/PACE; CAN-only chip access is
Android-only. See [KYC-V2.md](../KYC-V2.md) and [VALIDATION.md](../VALIDATION.md)
for the wire contract and the exact validation status.
