import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legichain_sdk/legichain_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('pending submission preserves the absence of a decision', () {
    final decision = KycDecision.fromJson({
      'application_id': 'tr_app', 'persona_id': 'tr_person',
      'pending': true, 'state': 'deciding', 'outcome': null,
      'decision_id': null,
    });
    expect(decision.pending, isTrue);
    expect(decision.outcome, isNull);
    expect(decision.decisionId, isNull);
    expect(const KycApplicationCreate(livenessRequired: false,
      faceMatchRequired: false).toJson()['liveness_required'], isFalse);
  });
  test('native bridge defaults to Turkish and returns submitted to host', () async {
    const channel = MethodChannel('legichain/kyc');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'start');
      expect(call.arguments['apiToken'], 'synthetic');
      expect(call.arguments['language'], 'tr');
      expect(call.arguments.containsKey('clientToken'), isFalse);
      return {'status': 'submitted', 'application_id': 'tr_app'};
    });
    final result = await LegichainKyc.start(apiToken: 'synthetic');
    expect(result.applicationId, 'tr_app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
