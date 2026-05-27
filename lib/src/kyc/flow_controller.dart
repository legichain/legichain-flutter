/// Stateful KYC orchestration for a single application.
///
/// The Flutter integration usually wants something like:
///
/// ```dart
/// final flow = await client.kyc.startFlow(...);
/// flow.stream.listen((s) => setState(() => step = s.currentStep));
/// await flow.uploadDocument(side: DocumentSide.single, jpegBytes: bytes);
/// await flow.uploadSelfie(jpegBytes: selfie);
/// final decision = await flow.submit();
/// ```
///
/// The controller:
///   * Stores `applicationId` + `clientToken` so callers stop
///     threading them through every method.
///   * Polls `/status` in the background (or subscribes to SSE if
///     [useEvents] is true), exposing a [stream] of [KycStatus].
///   * Honours retry semantics — `retryAvailable` from status
///     drives the UI.
///   * Handles NFC access-error retries (see [reportNfcAccessError]).
library;

import 'dart:async';

import '../client.dart';
import '../errors.dart';
import '../kyc_api.dart';
import '../models/common.dart';
import '../models/kyc.dart';

class KycFlowController {
  final KycApi _api;
  final KycApplicationCreated created;

  /// Internal mutable state. `latest` is what consumers should read;
  /// the [stream] emits this object every time it changes.
  KycStatus? _latest;
  final _ctl = StreamController<KycStatus>.broadcast();

  Timer? _pollTimer;
  StreamSubscription<KycStatus>? _eventsSub;
  bool _disposed = false;

  KycFlowController({
    required LegichainClient client,
    required this.created,
  }) : _api = client.kyc;

  // ── Public state accessors ─────────────────────────────────────
  String get applicationId => created.applicationId;
  String get personaId => created.personaId;
  String get clientToken => created.clientToken;
  KycStatus? get latest => _latest;

  Stream<KycStatus> get stream => _ctl.stream;

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Start polling `/status` at [interval] (default 2 s). When SSE
  /// is preferred set [useEvents] = true; we fall back to polling
  /// automatically if the SSE connection drops twice.
  Future<void> startListening({
    Duration interval = const Duration(seconds: 2),
    bool useEvents = true,
  }) async {
    if (_disposed) throw LegichainStateError('controller is disposed');
    await refresh(); // emit immediately
    if (useEvents) {
      _eventsSub = _api
          .events(
            applicationId: applicationId,
            clientToken: clientToken,
          )
          .listen(
            _emit,
            onError: (_) {
              // fall back to polling on SSE failure
              _eventsSub?.cancel();
              _eventsSub = null;
              _startPolling(interval);
            },
            onDone: () {
              _eventsSub = null;
            },
          );
    } else {
      _startPolling(interval);
    }
  }

  void _startPolling(Duration interval) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      try {
        await refresh();
        if (_latest?.isTerminal ?? false) {
          _pollTimer?.cancel();
          _pollTimer = null;
        }
      } catch (_) {
        // swallow transient errors; keep polling
      }
    });
  }

  Future<KycStatus> refresh() async {
    final s = await _api.getStatus(applicationId);
    _emit(s);
    return s;
  }

  void _emit(KycStatus s) {
    _latest = s;
    if (!_ctl.isClosed) _ctl.add(s);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    await _eventsSub?.cancel();
    await _ctl.close();
  }

  // ── Artefact uploads — wrappers that supply clientToken + appId ─

  Future<DocumentSubmitResponse> uploadDocument({
    required DocumentSide side,
    required List<int> jpegBytes,
    DocumentType? documentType,
    String mimeType = 'image/jpeg',
  }) {
    return _api.uploadDocument(
      applicationId: applicationId,
      clientToken: clientToken,
      documentType: documentType ?? DocumentType.passport,
      side: side,
      imageBytes: jpegBytes,
      mimeType: mimeType,
    );
  }

  Future<NfcSubmitResponse> submitNfcRead({
    required String protocol,
    String? keyDerivation,
    required List<int> sod,
    List<int>? dg1,
    List<int>? dg2,
    List<int>? dg11,
    List<int>? dg14,
    List<int>? dg15,
    List<int>? activeAuthentication,
  }) {
    return _api.submitNfc(
      applicationId: applicationId,
      clientToken: clientToken,
      protocol: protocol,
      keyDerivation: keyDerivation,
      sodBytes: sod,
      dg1: dg1,
      dg2: dg2,
      dg11: dg11,
      dg14: dg14,
      dg15: dg15,
      activeAuthentication: activeAuthentication,
    );
  }

  /// Report a chip-read failure (no SOD obtained). Keeps state at
  /// `awaiting_nfc` so the user can hand-retry.
  Future<NfcSubmitResponse> reportNfcAccessError({
    String protocol = 'PACE',
    String code = 'chip_not_responding',
  }) =>
      _api.submitNfcAccessError(
        applicationId: applicationId,
        clientToken: clientToken,
        protocol: protocol,
        code: code,
      );

  Future<Map<String, dynamic>> uploadSelfie({
    required List<int> jpegBytes,
    String mimeType = 'image/jpeg',
  }) =>
      _api.uploadSelfie(
        applicationId: applicationId,
        clientToken: clientToken,
        imageBytes: jpegBytes,
        mimeType: mimeType,
      );

  Future<LivenessChallenge> issueLivenessChallenge({
    int length = 3,
    int ttlSeconds = 60,
  }) =>
      _api.issueLivenessChallenge(
        applicationId: applicationId,
        clientToken: clientToken,
        length: length,
        ttlSeconds: ttlSeconds,
      );

  Future<Map<String, dynamic>> submitLiveness({
    required String challengeToken,
    required List<String> actionsPerformed,
    List<List<int>>? frames,
    double? padScore,
  }) =>
      _api.submitLiveness(
        applicationId: applicationId,
        clientToken: clientToken,
        challengeToken: challengeToken,
        actionsPerformed: actionsPerformed,
        frames: frames,
        padScore: padScore,
      );

  Future<KycDecision> submit() => _api.submit(
        applicationId: applicationId,
        clientToken: clientToken,
      );

  /// Customer-initiated retry. Only call when the latest status has
  /// `retryAvailable: true` (the wrapper enforces it).
  Future<void> retry({String? reason}) async {
    final s = _latest;
    if (s == null || !s.retryAvailable) {
      throw LegichainStateError(
        'retry not available from state ${s?.state} '
        '(attempt ${s?.currentAttempt}/${s?.maxAttempts})',
      );
    }
    await _api.requestRetry(
      applicationId: applicationId,
      clientToken: clientToken,
      reason: reason,
    );
    await refresh();
  }

  Future<void> extendTtl() async {
    await _api.extendTtl(
      applicationId: applicationId,
      clientToken: clientToken,
    );
    await refresh();
  }
}
