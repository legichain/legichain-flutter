/// Personas — optional cross-application identity grouping.
library;

import 'client.dart';

class PersonasApi {
  final LegichainClient _c;
  PersonasApi(this._c);

  Future<Map<String, dynamic>> create({
    String? subjectExternalId,
    String? displayName,
    Map<String, dynamic>? meta,
  }) =>
      _c.postJson('/v1/personas', body: {
        if (subjectExternalId != null) 'subject_external_id': subjectExternalId,
        if (displayName != null) 'display_name': displayName,
        if (meta != null) 'meta': meta,
      });

  Future<Map<String, dynamic>> list({
    String? subjectExternalId,
    int limit = 50,
    String? cursor,
  }) =>
      _c.getJson('/v1/personas', query: {
        if (subjectExternalId != null) 'subject_external_id': subjectExternalId,
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
      });

  Future<Map<String, dynamic>> get(String personaId) =>
      _c.getJson('/v1/personas/$personaId');
}
