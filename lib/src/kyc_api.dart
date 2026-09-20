/// KYC API surface — thin wrappers over each endpoint plus a
/// convenience `startFlow` that hands back a [KycFlowController].
library;

import 'dart:convert';

import 'client.dart';
import 'kyc/flow_controller.dart';
import 'models/common.dart';
import 'models/kyc.dart';

class KycApi {
  final LegichainClient _c;
  KycApi(this._c);

  /// Create a KYC application. Returns ids + a short-lived
  /// `clientToken` the SDK uses on every per-artefact call.
  Future<KycApplicationCreated> createApplication(
      KycApplicationCreate req) async {
    final r = await _c.postJson('/v1/kyc/applications', body: req.toJson());
    return KycApplicationCreated.fromJson(r);
  }

  /// One-shot: create the application AND wrap it in a flow controller.
  /// 90% of integrations want this.
  Future<KycFlowController> startFlow({
    String? subjectExternalId,
    String? personaId,
    String? externalReference,
    Intent intent = Intent.onboarding,
    List<DocumentType> documentTypes = const [
      DocumentType.trIdCard,
      DocumentType.passport,
    ],
    bool nfcRequired = false,
    bool? livenessRequired,
    bool? faceMatchRequired,
    String? callbackUrl,
    String? claimedFullName,
    String? claimedPersonalNumber,
    DateTime? claimedBirthDate,
    DateTime? claimedExpiryDate,
    String? claimedDocumentNumber,
    String? claimedNationality,
    String? claimedIssuingCountry,
    Sex? claimedSex,
    DocumentType? claimedDocumentType,
  }) async {
    final created = await createApplication(KycApplicationCreate(
      subjectExternalId: subjectExternalId,
      personaId: personaId,
      externalReference: externalReference,
      intent: intent,
      documentTypeAllowed: documentTypes,
      nfcRequired: nfcRequired,
      livenessRequired: livenessRequired,
      faceMatchRequired: faceMatchRequired,
      callbackUrl: callbackUrl,
      claimedFullName: claimedFullName,
      claimedPersonalNumber: claimedPersonalNumber,
      claimedBirthDate: claimedBirthDate,
      claimedExpiryDate: claimedExpiryDate,
      claimedDocumentNumber: claimedDocumentNumber,
      claimedNationality: claimedNationality,
      claimedIssuingCountry: claimedIssuingCountry,
      claimedSex: claimedSex,
      claimedDocumentType: claimedDocumentType,
    ));
    return KycFlowController(client: _c, created: created);
  }

  Future<KycStatus> getStatus(String applicationId,
      {bool includeExtracted = false}) async {
    final r = await _c.getJson(
      '/v1/kyc/applications/$applicationId/status',
      query: includeExtracted ? {'include_extracted': 'true'} : null,
    );
    return KycStatus.fromJson(r);
  }

  /// Upload one side of a document image. JPEG/PNG/HEIC bytes.
  Future<DocumentSubmitResponse> uploadDocument({
    required String applicationId,
    required String clientToken,
    required DocumentType documentType,
    required DocumentSide side,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    DateTime? capturedAt,
  }) async {
    final body = <String, dynamic>{
      'document_type': documentType.wire,
      'side': side.wire,
      'mime_type': mimeType,
      'image_b64': base64Encode(imageBytes),
    };
    if (capturedAt != null) {
      body['captured_at_client'] = capturedAt.toUtc().toIso8601String();
    }
    final r = await _c.postJson(
      '/v1/kyc/applications/$applicationId/documents',
      body: body,
      clientToken: clientToken,
    );
    return DocumentSubmitResponse.fromJson(r);
  }

  /// Submit a normal NFC chip read (SOD + DG payloads from BAC/PACE).
  Future<NfcSubmitResponse> submitNfc({
    required String applicationId,
    required String clientToken,
    required String protocol, // 'BAC' or 'PACE'
    String? keyDerivation, // 'MRZ' or 'CAN'
    required List<int> sodBytes,
    List<int>? dg1,
    List<int>? dg2,
    List<int>? dg7,
    List<int>? dg12,
    List<int>? dg13,
    Map<String, dynamic>? deviceAttestation,
    List<int>? dg11,
    List<int>? dg14,
    List<int>? dg15,
    List<int>? activeAuthentication,
  }) async {
    final body = <String, dynamic>{
      'protocol': protocol,
      'access_error': false,
      'sod_b64': base64Encode(sodBytes),
    };
    if (keyDerivation != null) body['key_derivation'] = keyDerivation;
    if (dg1 != null) body['dg1_b64'] = base64Encode(dg1);
    if (dg2 != null) body['dg2_b64'] = base64Encode(dg2);
    if (dg7 != null) body['dg7_b64'] = base64Encode(dg7);
    if (dg12 != null) body['dg12_b64'] = base64Encode(dg12);
    if (dg13 != null) body['dg13_b64'] = base64Encode(dg13);
    if (deviceAttestation != null) body['device_attestation'] = deviceAttestation;
    if (dg11 != null) body['dg11_b64'] = base64Encode(dg11);
    if (dg14 != null) body['dg14_b64'] = base64Encode(dg14);
    if (dg15 != null) body['dg15_b64'] = base64Encode(dg15);
    if (activeAuthentication != null) {
      body['active_authentication_b64'] = base64Encode(activeAuthentication);
    }
    final r = await _c.postJson(
      '/v1/kyc/applications/$applicationId/nfc',
      body: body,
      clientToken: clientToken,
    );
    return NfcSubmitResponse.fromJson(r);
  }

  /// Report a chip-access failure (antenna noise, CAN required, …).
  /// Keeps the application at `awaiting_nfc` so the SDK can retry the
  /// read without burning an attempt counter.
  Future<NfcSubmitResponse> submitNfcAccessError({
    required String applicationId,
    required String clientToken,
    required String protocol,
    String code = 'chip_not_responding',
  }) async {
    final r = await _c.postJson(
      '/v1/kyc/applications/$applicationId/nfc',
      body: {
        'protocol': protocol,
        'access_error': true,
        'access_error_code': code,
      },
      clientToken: clientToken,
    );
    return NfcSubmitResponse.fromJson(r);
  }

  Future<Map<String, dynamic>> uploadSelfie({
    required String applicationId,
    required String clientToken,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    bool isVideo = false,
  }) =>
      _c.postJson(
        '/v1/kyc/applications/$applicationId/selfie',
        body: {
          'mime_type': mimeType,
          'image_b64': base64Encode(imageBytes),
          'is_video': isVideo,
        },
        clientToken: clientToken,
      );

  Future<LivenessChallenge> issueLivenessChallenge({
    required String applicationId,
    required String clientToken,
    int length = 3,
    int ttlSeconds = 60,
  }) async {
    final r = await _c.postJson(
      '/v1/kyc/applications/$applicationId/liveness/challenge',
      body: {'length': length, 'ttl_seconds': ttlSeconds},
      clientToken: clientToken,
    );
    return LivenessChallenge.fromJson(r);
  }

  Future<Map<String, dynamic>> submitLiveness({
    required String applicationId,
    required String clientToken,
    required String mode,
    required List<int> frameBytes,
    String frameMimeType = 'image/jpeg',
    String? challengeToken,
    List<Map<String, dynamic>> completedActions = const [],
    List<Map<String, dynamic>> frames = const [],
    Map<String, dynamic>? deviceAttestation,
  }) =>
      _c.postJson(
        '/v1/kyc/applications/$applicationId/liveness',
        body: {
          'mode': mode,
          'frame_b64': base64Encode(frameBytes),
          'frame_mime_type': frameMimeType,
          if (challengeToken != null) 'challenge_token': challengeToken,
          'completed_actions': completedActions,
          'frames': frames,
          if (deviceAttestation != null) 'device_attestation': deviceAttestation,
        },
        clientToken: clientToken,
      );

  Future<KycDecision> submit({
    required String applicationId,
    required String clientToken,
  }) async {
    final r = await _c.postJson(
      '/v1/kyc/applications/$applicationId/submit',
      body: {},
      clientToken: clientToken,
    );
    return KycDecision.fromJson(r);
  }

  Future<Map<String, dynamic>> requestRetry({
    required String applicationId,
    required String clientToken,
    String? reason,
  }) =>
      _c.postJson(
        '/v1/kyc/applications/$applicationId/retry',
        body: reason == null ? {} : {'reason': reason},
        clientToken: clientToken,
      );

  Future<Map<String, dynamic>> extendTtl({
    required String applicationId,
    required String clientToken,
  }) =>
      _c.postJson(
        '/v1/kyc/applications/$applicationId/extend-ttl',
        clientToken: clientToken,
      );

  /// SSE event stream. Each emission is a KYC status payload —
  /// the SDK parses it for you and yields a [KycStatus].
  Stream<KycStatus> events({
    required String applicationId,
    required String clientToken,
  }) =>
      _c
          .openEventStream(
            path: '/v1/kyc/applications/$applicationId/events',
            clientToken: clientToken,
          )
          .map(KycStatus.fromJson);
}
