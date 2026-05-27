/// Address Verification — full surface.
library;

import 'dart:convert';

import 'client.dart';
import 'models/av.dart';

class AddressVerificationApi {
  final LegichainClient _c;
  AddressVerificationApi(this._c);

  Future<AVCreated> create(AVCreate req) async {
    final r = await _c.postJson('/v1/address-verifications', body: req.toJson());
    return AVCreated.fromJson(r);
  }

  Future<AVProofUploaded> uploadProof({
    required String verificationId,
    required String clientToken,
    required AVDocumentType documentType,
    required String mimeType,
    required List<int> imageBytes,
    DateTime? capturedAt,
  }) async {
    final body = <String, dynamic>{
      'document_type': documentType.wire,
      'mime_type': mimeType,
      'image_b64': base64Encode(imageBytes),
    };
    if (capturedAt != null) {
      body['captured_at_client'] = capturedAt.toUtc().toIso8601String();
    }
    final r = await _c.postJson(
      '/v1/address-verifications/$verificationId/proof',
      body: body,
      clientToken: clientToken,
    );
    return AVProofUploaded.fromJson(r);
  }

  Future<Map<String, dynamic>> submit({
    required String verificationId,
    required String clientToken,
  }) =>
      _c.postJson(
        '/v1/address-verifications/$verificationId/submit',
        body: {},
        clientToken: clientToken,
      );

  Future<AVStatus> getStatus(String verificationId) async {
    final r = await _c.getJson('/v1/address-verifications/$verificationId/status');
    return AVStatus.fromJson(r);
  }
}
