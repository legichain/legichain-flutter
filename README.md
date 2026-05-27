# Legichain Flutter SDK

Official Flutter client for the **[Legichain](https://legichain.com)** KYC,
AML / sanctions screening, and address-verification API.

```yaml
# pubspec.yaml
dependencies:
  legichain_sdk: ^1.0.0
```

[![pub.dev](https://img.shields.io/pub/v/legichain_sdk.svg)](https://pub.dev/packages/legichain_sdk)
[![License](https://img.shields.io/github/license/legichain/legichain-flutter.svg)](https://github.com/legichain/legichain-flutter/blob/main/LICENSE)

- One API key wraps every customer-facing `/v1` endpoint.
- KYC `startFlow()` returns a stateful controller — polling, SSE, retry,
  NFC submission, image-quality gating included.
- Pure-Dart Laplacian blur gate + MRZ pattern hint for on-device IQA.
- Pluggable `NfcReader` interface — bring your own eMRTD chip library.
- AML / sanctions / PEP / crypto wallet screening.
- Address verification with proof upload.

## Get an API key

Sign up at **<https://legichain.com>** — the Free plan ships with 1 RPS
and 300 monthly credits, no card required.

> **panel.legichain.com → API keys → New key**

Keys look like `lc_live_<22>.sk_live_<44>` (production) or
`lc_test_<22>.sk_test_<44>` (test mode, never spends credits). Store
the secret half in your secret manager — it's shown once. See the
[full API guide](https://github.com/legichain/legichain/tree/main/docs/api-public)
for plans, rate limits and the OpenAPI spec.

---

## Quick start

```dart
import 'package:legichain_sdk/legichain_sdk.dart';

final client = LegichainClient(apiKey: 'lc_live_xxxxxxxx.sk_live_xxxxxxxx');

// AML screening
final r = await client.screening.person(name: 'Vladimir Putin', country: 'RU');
if (r.summary.recommendation == ScreeningRecommendation.block) { /* deny */ }

// KYC orchestrated flow — polling/SSE + retry in one line
final flow = await client.kyc.startFlow(
  subjectExternalId: 'your-user-42',
  documentTypes: [DocumentType.passport],
  claimedFullName: 'ERIKA MUSTERMANN',
  claimedNationality: 'DEU',
);
await flow.startListening();
flow.stream.listen((s) => print('${s.currentStep} ${s.currentAttempt}'));
await flow.uploadDocument(side: DocumentSide.single, jpegBytes: bytes);
await flow.uploadSelfie(jpegBytes: selfieBytes);
final decision = await flow.submit();
print('${decision.outcome} risk=${decision.riskScore}');
```

## NFC chip reads

This SDK ships an interface, not a chip-stack implementation — ICAO
9303 BAC + PACE + SOD verification is 5-10k LOC. Plug in the chip
library of your choice:

Recommended packages:
- [`nfc_manager`](https://pub.dev/packages/nfc_manager) — low-level chip session on iOS + Android.
- [`dmrtd`](https://pub.dev/packages/dmrtd) — Dart port of JMRTD with BAC + DG parsing + SOD verification.

Once you have raw bytes, hand them to the flow:

```dart
await flow.submitNfcRead(
  protocol: 'PACE', sod: r.sod,
  dg1: r.dg1, dg2: r.dg2, dg14: r.dg14, dg15: r.dg15,
);
```

If the chip didn't respond (antenna noise, CAN required), call
`flow.reportNfcAccessError()` — server keeps state at `awaiting_nfc`
so the user retries without burning an attempt.

## Image-quality gate

```dart
final gate = ImageQualityGate(blurThreshold: 100);
gate.mustPass(grayscale: grayBytes, width: w, height: h);
```

Pure-Dart Laplacian variance sample. Pair with platform OCR
(`google_mlkit_text_recognition`, Apple Vision) and
`ImageQualityGate.detectMrzLines(...)` to gate the data page on real
MRZ visibility before uploading.

## Error handling

```dart
try {
  await flow.uploadDocument(...);
} on LegichainException catch (e) {
  if (e.code == 'KYC_INVALID_CLIENT_TOKEN') {
    // application TTL hit — start a new one
  } else if (e.status == 429) {
    await Future.delayed(Duration(seconds: 5));
  }
}
```

Stable codes are documented in the
[public API guide](https://github.com/legichain/legichain/tree/main/docs/api-public).

## Other SDKs

| Platform | Repo |
|---|---|
| iOS (native) | [legichain-ios](https://github.com/legichain/legichain-ios) |
| Android (native) | [legichain-android](https://github.com/legichain/legichain-android) |
| React Native | [legichain-react-native](https://github.com/legichain/legichain-react-native) |
| Python | [legichain-python](https://github.com/legichain/legichain-python) |
| Node.js / TypeScript | [legichain-node](https://github.com/legichain/legichain-node) |
| Go | [legichain-go](https://github.com/legichain/legichain-go) |
| Java | [legichain-java](https://github.com/legichain/legichain-java) |
| .NET / C# | [legichain-dotnet](https://github.com/legichain/legichain-dotnet) |

Server-side platform code, OpenAPI spec and Postman collection live in
the main monorepo at
**[legichain/legichain](https://github.com/legichain/legichain)**.

## License

MIT — see [LICENSE](LICENSE).
