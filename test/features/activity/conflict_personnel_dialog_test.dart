import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/conflict_personnel_dialog.dart';

void main() {
  testWidgets('shows conflicts as clear personnel cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConflictPersonnelDialog(
            descriptions: [
              'Kudret SARIOĞLU: 2026-07-30 tarihinde mevcut kaydı nedeniyle '
                  'Günlük Tüm Faaliyetler faaliyetine eklenmedi.',
              'Emin SOLUKEL: 2026-07-30 tarihinde mevcut kaydı nedeniyle '
                  'Gece Devriyesi faaliyetine eklenmedi.',
            ],
          ),
        ),
      ),
    );

    expect(find.text('Bazı personeller eklenmedi'), findsOneWidget);
    expect(find.textContaining('2 personel atlandı'), findsOneWidget);
    expect(find.text('Kudret SARIOĞLU'), findsOneWidget);
    expect(find.text('30.07.2026'), findsWidgets);
    expect(find.text('Günlük Tüm Faaliyetler'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Emin SOLUKEL'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('conflict-personnel-list')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.text('Emin SOLUKEL'), findsOneWidget);
    expect(find.text('Gece Devriyesi'), findsOneWidget);
    expect(find.text('ANLADIM'), findsOneWidget);
  });
}
