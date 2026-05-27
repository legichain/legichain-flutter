/// AML / sanctions screening.
library;

import 'client.dart';
import 'models/screening.dart';

class ScreeningApi {
  final LegichainClient _c;
  ScreeningApi(this._c);

  /// Screen a person against sanctions / PEP / wanted / adverse media.
  ///
  /// 1 credit per call. The returned [ScreeningResponse.summary.recommendation]
  /// gives a one-line `clear | review | block` verdict.
  Future<ScreeningResponse> person({
    required String name,
    String? country,
    String? dob,
    String? document,
    List<String>? topics,
    int? topN,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (country != null) body['country'] = country;
    if (dob != null) body['dob'] = dob;
    if (document != null) body['document'] = document;
    if (topics != null) body['topics'] = topics;
    if (topN != null) body['top_n'] = topN;
    final r = await _c.postJson('/v1/screen/person', body: body);
    return ScreeningResponse.fromJson(r);
  }

  /// Screen a company / organisation.
  Future<ScreeningResponse> company({
    required String name,
    String? country,
    String? registrationNumber,
    int? topN,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (country != null) body['country'] = country;
    if (registrationNumber != null) {
      body['registration_number'] = registrationNumber;
    }
    if (topN != null) body['top_n'] = topN;
    final r = await _c.postJson('/v1/screen/company', body: body);
    return ScreeningResponse.fromJson(r);
  }

  /// Screen a blockchain wallet address. Cost: 3 credits.
  ///
  /// [chain] is optional but speeds the lookup; supported values:
  /// `BTC`, `ETH`, `TRX`, `BNB`, `XMR`, `SOL`, `LTC`, `BCH`, …
  Future<ScreeningResponse> crypto({
    required String address,
    String? chain,
  }) async {
    final body = <String, dynamic>{'address': address};
    if (chain != null) body['chain'] = chain;
    final r = await _c.postJson('/v1/screen/crypto', body: body);
    return ScreeningResponse.fromJson(r);
  }

  /// Synchronous batch screening — up to 200 items. Single response.
  /// Each item is a [Map] matching the corresponding endpoint's body.
  Future<List<ScreeningResponse>> batch(List<Map<String, dynamic>> items) async {
    final r = await _c.request(
      method: 'POST',
      path: '/v1/screen/batch',
      body: {'items': items},
    ) as List?;
    return (r ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ScreeningResponse.fromJson)
        .toList();
  }

  /// Async batch — returns a job id. Poll [batchJobStatus] for results.
  Future<({String jobId, String status, int totalItems})> batchAsync(
      List<Map<String, dynamic>> items) async {
    final r = await _c.postJson('/v1/screen/batch/async',
        body: {'items': items});
    return (
      jobId: r['job_id'] as String,
      status: r['status'] as String,
      totalItems: (r['total_items'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<Map<String, dynamic>> batchJobStatus(String jobId) =>
      _c.getJson('/v1/screen/jobs/$jobId');
}
