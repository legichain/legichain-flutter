/// RFC 7807 Problem-Details translated to Dart exceptions.
///
/// All API errors throw [LegichainException]. Branch on
/// [LegichainException.code] (the stable Legichain identifier),
/// never on [message] (the human-readable text — it can change).
library;

class LegichainException implements Exception {
  /// HTTP status code (401, 404, 409, 422, …).
  final int status;

  /// Stable Legichain error code, e.g.
  /// `KYC_006_INVALID_STATE_TRANSITION`.
  final String code;

  /// Human-readable detail. Surfaced to operators / logs; do not
  /// localise or display unmodified to end users.
  final String message;

  /// Raw Problem-Details payload — the entire response body.
  final Map<String, dynamic> problem;

  const LegichainException({
    required this.status,
    required this.code,
    required this.message,
    this.problem = const {},
  });

  @override
  String toString() => 'LegichainException($status $code): $message';
}

/// Thrown when an SDK pre-condition fails (e.g. uploading a doc on a
/// flow that hasn't been started). Distinct from server errors.
class LegichainStateError implements Exception {
  final String message;
  LegichainStateError(this.message);
  @override
  String toString() => 'LegichainStateError: $message';
}

/// Thrown by the on-device IQA gate when the captured frame is not
/// good enough to upload (blur, MRZ missing, …).
class LegichainCaptureRejected implements Exception {
  /// Short, programmer-friendly reason: `image_blurred`,
  /// `document_outline_not_found`, `mrz_not_visible`, …
  final String reason;
  const LegichainCaptureRejected(this.reason);
  @override
  String toString() => 'LegichainCaptureRejected: $reason';
}
