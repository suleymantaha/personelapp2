import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('first login validates the new password dialog', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.ensureSeeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Kullanıcı Adı'),
      'admin',
    );
    await tester.tap(find.text('GİRİŞ YAP'));
    await tester.pumpAndSettle();

    expect(find.text('İlk Giriş: Parola Belirleyin'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Yeni Parola'),
      'kisa',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Yeni Parola (Tekrar)'),
      'kisa',
    );
    await tester.tap(find.text('PAROLAYI KAYDET VE GİRİŞ YAP'));
    await tester.pump();

    expect(find.text('Parola en az 12 karakter olmalıdır.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Yeni Parola'),
      'guvenli-parola-1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Yeni Parola (Tekrar)'),
      'guvenli-parola-2',
    );
    await tester.tap(find.text('PAROLAYI KAYDET VE GİRİŞ YAP'));
    await tester.pump();

    expect(find.text('Parolalar eşleşmiyor!'), findsOneWidget);
  });
}
