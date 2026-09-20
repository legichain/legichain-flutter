import 'package:flutter/services.dart';

enum KycLanguage { tr, en }

class NativeKycResult {
  final String status;
  final String applicationId;
  const NativeKycResult({required this.status, required this.applicationId});
  bool get submitted => status == 'submitted';
}

/// Ready-to-use native camera, NFC and active-liveness flow.
/// All requests go directly from the app to Legichain using one API token.
class LegichainKyc {
  static const _channel = MethodChannel('legichain/kyc');
  static Future<NativeKycResult> start({
    required String apiToken,
    String baseUrl = 'https://api.legichain.com',
    KycLanguage language = KycLanguage.tr,
    Map<String, dynamic> application = const {},
  }) async {
    if (apiToken.trim().isEmpty) throw ArgumentError('apiToken is required');
    final result = await _channel.invokeMapMethod<String, dynamic>('start', {
      'apiToken': apiToken, 'baseUrl': baseUrl, 'language': language.name,
      'application': application,
    });
    if (result == null || !['submitted', 'cancelled'].contains(result['status'])) {
      throw const FormatException('Invalid native KYC result');
    }
    return NativeKycResult(status: result['status'] as String,
        applicationId: result['application_id'] as String? ?? '');
  }
}
