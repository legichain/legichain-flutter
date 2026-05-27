/// Webhooks — subscribe / list / test / delete.
library;

import 'client.dart';

class WebhooksApi {
  final LegichainClient _c;
  WebhooksApi(this._c);

  /// Subscribe. The `secret` field on the response is returned ONCE —
  /// store it server-side; needed to verify HMAC signatures.
  Future<Map<String, dynamic>> subscribe({
    required String url,
    required List<String> eventTypes,
    String? description,
  }) =>
      _c.postJson('/v1/admin/webhooks', body: {
        'url': url,
        'event_types': eventTypes,
        if (description != null) 'description': description,
      });

  Future<List<dynamic>> list() async {
    final r = await _c.request(method: 'GET', path: '/v1/admin/webhooks');
    return (r as List?) ?? const [];
  }

  Future<void> delete(String webhookId) =>
      _c.delete('/v1/admin/webhooks/$webhookId');

  Future<void> test(String webhookId) async {
    await _c.postJson('/v1/admin/webhooks/$webhookId/test');
  }
}
