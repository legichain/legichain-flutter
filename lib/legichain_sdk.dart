/// Legichain SDK — public surface for Flutter apps.
///
/// Tenants get one entry point: [LegichainClient]. Construct it with
/// the API key from `panel.legichain.com/app/api-keys`, then call:
///
/// ```dart
/// final c = LegichainClient(apiKey: 'key_xxx.secret_yyy');
///
/// // AML screening
/// final r = await c.screening.person(name: 'Vladimir Putin', country: 'RU');
/// if (r.summary.recommendation == ScreeningRecommendation.block) { ... }
///
/// // KYC — orchestrated flow
/// final flow = await c.kyc.startFlow(
///   subjectExternalId: 'your-user-42',
///   documentTypes: [DocumentType.passport],
/// );
/// flow.stream.listen((s) => print('${s.currentStep} (${s.currentAttempt})'));
/// await flow.uploadDocument(side: DocumentSide.single, jpegBytes: bytes);
/// await flow.uploadSelfie(jpegBytes: selfieBytes);
/// final decision = await flow.submit();
///
/// // Address verification
/// final av = await c.addressVerification.create(
///   subjectExternalId: 'your-user-42',
///   claimedAddress: ClaimedAddress(country: 'TR', city: 'İstanbul'),
/// );
/// ```
library legichain_sdk;

export 'src/client.dart';
export 'src/errors.dart';
export 'src/screening_api.dart';
export 'src/kyc_api.dart';
export 'src/address_verification_api.dart';
export 'src/personas_api.dart';
export 'src/webhooks_api.dart';
export 'src/kyc/flow_controller.dart';
export 'src/kyc/quality_gate.dart';
export 'src/kyc/nfc_reader.dart';
export 'src/models/common.dart';
export 'src/models/screening.dart';
export 'src/models/kyc.dart';
export 'src/models/av.dart';
