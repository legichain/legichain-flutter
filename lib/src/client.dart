/// Root client — single entry point holding HTTP + auth + sub-APIs.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_verification_api.dart';
import 'errors.dart';
import 'kyc_api.dart';
import 'personas_api.dart';
import 'screening_api.dart';
import 'webhooks_api.dart';

class LegichainClient {
  /// `key_xxx.secret_yyy` — get one from `/app/api-keys` in the panel.
  final String apiKey;

  /// Base URL. Defaults to production.
  final String baseUrl;

  /// Default request timeout. Per-call overrides are accepted by the
  /// sub-APIs where it matters (large uploads, SSE, …).
  final Duration timeout;

  /// Injectable HTTP client — handy for testing with `MockClient` or
  /// for tenants who already have a custom interceptor stack.
  final http.Client _http;
  final bool _ownsHttp;

  /// Optional User-Agent suffix appended after `legichain-flutter-sdk/<v>`
  /// so we can identify integrations in logs.
  final String? userAgent;

  LegichainClient({
    required this.apiKey,
    this.baseUrl = 'https://panel.legichain.com',
    this.timeout = const Duration(seconds: 30),
    http.Client? httpClient,
    this.userAgent,
  })  : _http = httpClient ?? http.Client(),
        _ownsHttp = httpClient == null;

  // ── Sub-APIs ───────────────────────────────────────────────────
  late final ScreeningApi screening = ScreeningApi(this);
  late final KycApi kyc = KycApi(this);
  late final AddressVerificationApi addressVerification =
      AddressVerificationApi(this);
  late final PersonasApi personas = PersonasApi(this);
  late final WebhooksApi webhooks = WebhooksApi(this);

  /// Cleanly close the internal HTTP client. Optional but recommended
  /// when you're sure the SDK is no longer needed (logout, etc.).
  void close() {
    if (_ownsHttp) _http.close();
  }

  // ── HTTP plumbing (internal, but visible to sub-APIs) ─────────

  /// Build the canonical request headers.
  Map<String, String> _headers({String? clientToken, String? idempotencyKey}) {
    final h = <String, String>{
      'authorization': 'Bearer $apiKey',
      'accept': 'application/json',
      'user-agent':
          'legichain-flutter-sdk/1.0.0${userAgent != null ? ' ($userAgent)' : ''}',
    };
    if (clientToken != null) h['x-kyc-client-token'] = clientToken;
    if (idempotencyKey != null) h['idempotency-key'] = idempotencyKey;
    return h;
  }

  /// Internal: GET/POST/DELETE wrapper. Returns the decoded JSON map
  /// (or list); throws [LegichainException] on non-2xx.
  Future<dynamic> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    String? clientToken,
    String? idempotencyKey,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(baseUrl + path).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v)),
    );
    final headers = _headers(
      clientToken: clientToken,
      idempotencyKey: idempotencyKey,
    );
    final bodyBytes = body == null
        ? null
        : () {
            headers['content-type'] = 'application/json';
            return utf8.encode(jsonEncode(body));
          }();

    final req = http.Request(method, uri)
      ..headers.addAll(headers)
      ..bodyBytes = bodyBytes ?? const <int>[];

    final resp = await _http.send(req).timeout(timeout ?? this.timeout);
    final responseBody = await resp.stream.bytesToString();

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      Map<String, dynamic> problem = const {};
      try {
        problem = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {/* non-JSON; keep empty */}
      throw LegichainException(
        status: resp.statusCode,
        code: (problem['code'] as String?) ?? 'HTTP_${resp.statusCode}',
        message: (problem['detail'] as String?) ??
            (problem['title'] as String?) ??
            'HTTP ${resp.statusCode}',
        problem: problem,
      );
    }
    if (responseBody.isEmpty) return null;
    return jsonDecode(responseBody);
  }

  // ── Convenience JSON helpers ──────────────────────────────────
  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, String>? query,
      String? clientToken,
      Duration? timeout}) async {
    final r = await request(
      method: 'GET',
      path: path,
      query: query,
      clientToken: clientToken,
      timeout: timeout,
    );
    return (r as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? clientToken,
    String? idempotencyKey,
    Duration? timeout,
  }) async {
    final r = await request(
      method: 'POST',
      path: path,
      body: body ?? {},
      clientToken: clientToken,
      idempotencyKey: idempotencyKey,
      timeout: timeout,
    );
    return (r as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String path, {String? clientToken}) async {
    await request(method: 'DELETE', path: path, clientToken: clientToken);
  }

  /// Internal: open a long-lived SSE stream against `path` and yield
  /// each `data: ...` payload as a parsed JSON map.
  Stream<Map<String, dynamic>> openEventStream({
    required String path,
    String? clientToken,
  }) async* {
    final uri = Uri.parse(baseUrl + path);
    final headers = _headers(clientToken: clientToken);
    headers['accept'] = 'text/event-stream';
    final req = http.Request('GET', uri)..headers.addAll(headers);
    final resp = await _http.send(req);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw LegichainException(
        status: resp.statusCode,
        code: 'SSE_${resp.statusCode}',
        message: 'event stream rejected',
      );
    }

    final buffer = StringBuffer();
    await for (final chunk
        in resp.stream.transform(utf8.decoder)) {
      buffer.write(chunk);
      var text = buffer.toString();
      // SSE framing: events separated by blank lines (\n\n).
      while (text.contains('\n\n')) {
        final idx = text.indexOf('\n\n');
        final frame = text.substring(0, idx);
        text = text.substring(idx + 2);
        // Parse the `data: ...` line(s) within the frame.
        final dataLines = frame
            .split('\n')
            .where((l) => l.startsWith('data:'))
            .map((l) => l.substring(5).trimLeft())
            .toList();
        if (dataLines.isEmpty) continue;
        final dataStr = dataLines.join('\n');
        try {
          yield jsonDecode(dataStr) as Map<String, dynamic>;
        } catch (_) {/* skip malformed frame */}
      }
      buffer
        ..clear()
        ..write(text);
    }
  }
}
