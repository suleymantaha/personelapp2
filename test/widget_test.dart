import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PersonelApp(),
      ),
    );
    expect(find.byType(PersonelApp), findsOneWidget);
  });
}
