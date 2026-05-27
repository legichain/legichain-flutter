# Changelog

## 1.0.0 — 2026-05-27

Initial public release.

- `LegichainClient` — single entry point, API-key auth.
- KYC: full SDK surface (`kyc.startFlow()`) + `KycFlowController`
  (polling + SSE + retry + NFC + IQA).
- AML / sanctions screening: person / company / crypto / batch.
- Address verification: create / proof / submit / status.
- Personas + Webhooks helpers.
- `NfcReader` abstract interface + `SimulatedNfcReader` for UI dev.
- `ImageQualityGate` — pure-Dart blur variance + MRZ pattern hint.
- Typed Problem-Details exceptions (`LegichainException`).
