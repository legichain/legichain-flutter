# Legichain flutter SDK v2

Official SDK for the existing Legichain API. [KYC v2 integration and migration](https://github.com/legichain/legichain-flutter/blob/main/KYC-V2.md)
contains the current wire contract, check flags, asynchronous evidence and
submission behavior. Version: **2.0.0**; publication status is tracked separately.

```dart
import 'package:legichain_sdk/legichain_sdk.dart';
final result = await LegichainKyc.start(
  apiToken: token, language: KycLanguage.tr,
  application: {'nfc_required': true},
);
// Native screen is closed. Continue with your app's screen.
// result.submitted does not mean identity approval.
```
Add `legichain_sdk: ^2.0.0` after publication and rebuild your Android/iOS app.
`example/` is a runnable host application with language choice and token entry.

See [validation status](VALIDATION.md) for completed checks and pending device acceptance.

## Included native flow

The package provides a full-screen document selector, camera frame, corner and
MRZ detection, stable auto capture, native NFC guidance animation and chip
reading, selfie, active liveness, retry/cancel and submitted/return screens.
Choose `tr` (default) or `en` before launch. Both languages are bundled;
the host completion result uses stable machine-readable status strings.

Turkish: “Doğrulama başvurunuz gönderildi.” English: “Your verification
application has been submitted.” The next message explains that the provider
will notify the applicant. Returning to the host does not await the webhook.

Active prompts are delivered before the start cue. A neutral pose is required
before each action, followed by actual camera detection and return to center.
Moving early, tapping a button or elapsed time alone cannot complete an action.
The payload includes observed timings and frames covering baseline, movement
and return. Backgrounding interrupts an active challenge and requires a fresh
challenge. Upload retries reuse the original capture and idempotency key.

Android: CameraX, ML Kit text/face, OpenCV corners, JMRTD + Scuba ISO-DEP.
iOS: AVFoundation, Vision rectangle/text/landmarks, NFCPassportReader 2.3.1.
Native code is shared into Flutter/RN; `native-source.json` records file hashes.
Dependencies are resolved by Gradle/CocoaPods/SPM, not simulated adapters.

## Host platform setup

Android minimum API 24, compile SDK 35+, Java 17. Use AndroidX. CAMERA and NFC
permissions and the non-exported KYC activity merge from the library manifest.
Keep the default consumer rules. Runtime camera permission is requested by the
flow. Required NFC on a device without an enabled NFC adapter blocks that step.

iOS minimum 15, Swift 5.9+. In the host target enable “Near Field Communication
Tag Reading”. Include `com.apple.developer.nfc.readersession.formats = [TAG]`
in signed entitlements. Add these Info.plist entries:

```xml
<key>NSCameraUsageDescription</key><string>Identity and liveness verification</string>
<key>NFCReaderUsageDescription</key><string>Read your identity document chip</string>
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array><string>A0000002471001</string></array>
```

Localize permission descriptions in `tr.lproj/InfoPlist.strings` and
`en.lproj/InfoPlist.strings` in your app. System permission language is controlled
by iOS, while the SDK screen language is selected in its options.

BAC and MRZ-based PACE are implemented. Android additionally supports CAN-based
PACE input. iOS CAN-only documents are not supported by the selected reader.
This release does not claim every eMRTD PACE profile or protected data group.
Passive/active authentication evidence is uploaded for backend verification.

## Device acceptance still required before release

Build/unit tests do not verify NFC antenna performance or camera calibration.
Test real BAC passport and PACE identity card reads, chip removal/retry, camera
permission denial, poor lighting, all five actions (including early movement),
background/foreground interruption, network failure during upload/submit,
TR/EN layouts, cancellation, and host return. Verify webhook outcome separately.
The current Windows build has no Xcode/device acceptance evidence. iPhone
testing requires a signed Xcode build on a Mac or an existing macOS CI build
delivered through TestFlight. NFC cannot be validated in an iOS simulator.

Android host `android {}` packaging configuration for Bouncy Castle OSGi metadata:

```kotlin
packaging { resources.excludes += "META-INF/versions/**/OSGI-INF/MANIFEST.MF" }
```

This excludes duplicate OSGi manifests only, not the cryptographic code or licenses.
