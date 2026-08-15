import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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

  testWidgets('PersonelApp installs the global notification host',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PersonelApp()));

    expect(find.byKey(const Key('app-notification-host')), findsOneWidget);
  });

  testWidgets('PersonelApp takvimleri Türkçe ve pazartesi başlangıçlı kurar',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PersonelApp()));

    final context =
        tester.element(find.byKey(const Key('app-notification-host')));
    final locale = Localizations.localeOf(context);
    final material = MaterialLocalizations.of(context);

    expect(locale, const Locale('tr', 'TR'));
    expect(material.datePickerHelpText, 'Tarih seçin');
    expect(material.cancelButtonLabel, 'İptal');
    expect(material.okButtonLabel, 'Tamam');
    expect(material.firstDayOfWeekIndex, 1);
  });
}
