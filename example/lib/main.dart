// Minimal demo of the Legichain Flutter SDK.
// Run `flutter pub get` then `flutter run`.

// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:legichain_sdk/legichain_sdk.dart';

const _apiKey = 'key_xxx.secret_yyy';      // ← paste yours

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Legichain Demo',
        theme: ThemeData.dark(useMaterial3: true),
        home: const _Home(),
      );
}

class _Home extends StatefulWidget {
  const _Home();
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final LegichainClient _client =
      LegichainClient(apiKey: _apiKey);
  KycFlowController? _flow;
  String _log = 'ready';

  @override
  void dispose() {
    _flow?.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _runScreening() async {
    setState(() => _log = 'screening…');
    final r = await _client.screening.person(
      name: 'Vladimir Putin',
      country: 'RU',
      topN: 5,
    );
    setState(() => _log =
        'recommendation=${r.summary.recommendation.name} '
        'hits=${r.hits.length} top_conf=${r.summary.topMatchConfidence}');
  }

  Future<void> _startKyc() async {
    setState(() => _log = 'creating application…');
    _flow = await _client.kyc.startFlow(
      subjectExternalId: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      documentTypes: const [DocumentType.passport],
      claimedFullName: 'ERIKA MUSTERMANN',
      claimedNationality: 'DEU',
    );
    await _flow!.startListening();
    _flow!.stream.listen((s) => setState(() => _log =
        'state=${s.state} step=${s.currentStep.name} '
        'attempt=${s.currentAttempt}/${s.maxAttempts} '
        'retry=${s.retryAvailable}'));
  }

  Future<void> _fakeUploadDoc() async {
    if (_flow == null) return;
    // Replace with real jpeg from a camera plugin.
    final fakeJpeg = Uint8List(2048);
    await _flow!.uploadDocument(
      side: DocumentSide.single,
      jpegBytes: fakeJpeg,
      documentType: DocumentType.passport,
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Legichain SDK demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _runScreening,
                child: const Text('Run AML screening'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _startKyc,
                child: const Text('Start KYC application'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _fakeUploadDoc,
                child: const Text('Upload (fake) document'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                  child:
                      SingleChildScrollView(child: SelectableText(_log))),
            ],
          ),
        ),
      );
}
