import 'package:flutter_test/flutter_test.dart';
import 'package:legichain_example/main.dart';
void main() {
  testWidgets('sample offers Turkish and English before launching', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('Doğrulamayı başlat'), findsOneWidget);
    await tester.tap(find.text('English')); await tester.pumpAndSettle();
    expect(find.text('Start verification'), findsOneWidget);
  });
}
