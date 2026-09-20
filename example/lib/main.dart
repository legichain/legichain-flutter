import 'package:flutter/material.dart';
import 'package:legichain_sdk/legichain_sdk.dart';

void main() => runApp(const DemoApp());
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff147d70))),
    home: const KycExample(),
  );
}
class KycExample extends StatefulWidget {
  const KycExample({super.key});
  @override
  State<KycExample> createState() => _KycExampleState();
}
class _KycExampleState extends State<KycExample> {
  final token = TextEditingController();
  KycLanguage language = KycLanguage.tr;
  bool nfc = true, busy = false;
  String message = '';
  bool get tr => language == KycLanguage.tr;
  @override
  void dispose() { token.dispose(); super.dispose(); }
  Future<void> start() async {
    setState(() { busy = true; message = ''; });
    try {
      final result = await LegichainKyc.start(apiToken: token.text.trim(), language: language,
        application: {'nfc_required': nfc, 'liveness_required': true, 'face_match_required': true});
      if (!mounted) return;
      setState(() { message = result.submitted
        ? (tr ? 'Başvurunuz gönderildi. Sonuç size bildirilecek.' : 'Application submitted. You will be notified of the result.')
        : (tr ? 'İşlem iptal edildi.' : 'Verification cancelled.'); });
    } catch (_) {
      if (mounted) setState(() { message = tr ? 'Akış başlatılamadı. Lütfen tekrar deneyin.' : 'Unable to start. Please try again.'; });
    } finally { if (mounted) setState(() { busy = false; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr ? 'Legichain örnek uygulama' : 'Legichain sample app')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      Text(tr ? 'Kimliğinizi doğrulayın' : 'Verify your identity', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      SegmentedButton<KycLanguage>(segments: const [
        ButtonSegment(value: KycLanguage.tr, label: Text('Türkçe')),
        ButtonSegment(value: KycLanguage.en, label: Text('English')),
      ], selected: {language}, onSelectionChanged: busy ? null : (value) => setState(() { language = value.first; })),
      const SizedBox(height: 24),
      TextField(controller: token, obscureText: true, autocorrect: false, enableSuggestions: false,
        decoration: InputDecoration(labelText: tr ? 'Legichain API tokeni (örnek uygulama)' : 'Legichain API token (sample app)')),
      SwitchListTile(title: Text(tr ? 'NFC çip okuma' : 'Read NFC chip'), value: nfc,
        onChanged: busy ? null : (value) => setState(() { nfc = value; })),
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : start, child: Text(tr ? 'Doğrulamayı başlat' : 'Start verification')),
      const SizedBox(height: 24), Text(message),
    ]),
  );
}
