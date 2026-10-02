import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
}

void main() {
  testWidgets('light warning badges remain readable over the card surface',
      (tester) async {
    final theme = AppTheme.militaryTheme;
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
          body: PersonnelMatchCard(
        item: ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'Yb.',
            rawName: 'Ahmet',
            matchedPersonnelId: 1,
            matchedAdSoyad: 'Ahmet',
            matchedRutbe: 'Yb.',
            matchConfidence: 1,
            teamMismatch: true),
        teamName: '1/B',
        onSelect: () {},
        onDelete: () {},
        onConfirmSuggestion: () {},
      )),
    ));
    final card =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final cardSurface = Color.alphaBlend(
        (card.decoration! as BoxDecoration).color!,
        theme.scaffoldBackgroundColor);
    for (final label in ['Tim disi gorev', 'Tim disi gorev (Kabul et)']) {
      final text = tester.widget<Text>(find.text(label));
      final badge = tester.widget<Container>(find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first);
      final background = Color.alphaBlend(
          (badge.decoration! as BoxDecoration).color!, cardSurface);
      expect(
          _contrast(text.style!.color!, background), greaterThanOrEqualTo(4.5),
          reason: label);
    }
  });

  testWidgets('dark alias deletion action keeps a readable foreground',
      (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final id = await database.into(database.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Ahmet',
            rutbe: 'Yb.',
            birlik: '1/B',
            kayitTarihi: '2026-01-01'));
    await BulkImportLearningService(database)
        .rememberAlias(rawName: 'Ahmt', personnelId: id);
    final theme = AppTheme.darkMilitaryTheme;
    await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                    onPressed: () =>
                        LearnedAliasesDialog.show(context, database),
                    child: const Text('Aç'))))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timsiz / Diğer Personeller'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    final finder = find.ancestor(
        of: find.text('SİL'), matching: find.byType(FilledButton));
    final button = tester.widget<FilledButton>(finder);
    final background = button.style!.backgroundColor!.resolve({})!;
    final foreground = button.style!.foregroundColor?.resolve({}) ??
        theme.colorScheme.onPrimary;
    expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
  });

  testWidgets('focused personnel stays readable in the dark theme', (
    tester,
  ) async {
    final theme = AppTheme.darkMilitaryTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: PersonnelMatchCard(
            item: ParsedPersonnelItem(
              rawIndex: 1,
              rawRank: 'Yb.',
              rawName: 'Ahmet Yılmaz',
              matchedPersonnelId: 1,
              matchedAdSoyad: 'Ahmet Yılmaz',
              matchedRutbe: 'Yb.',
              matchConfidence: 1,
            ),
            teamName: '1/B',
            isFocused: true,
            onSelect: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(PersonnelMatchCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final background = (container.decoration! as BoxDecoration).color!;
    expect(
      _contrast(theme.colorScheme.onSurface, background),
      greaterThanOrEqualTo(4.5),
    );
    final badge = tester.widget<Text>(find.text('İNCELENEN PERSONEL'));
    final badgeContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('İNCELENEN PERSONEL'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      _contrast(
        badge.style!.color!,
        (badgeContainer.decoration! as BoxDecoration).color!,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });

  for (final dark in [false, true]) {
    testWidgets('new personnel action has readable text (dark: $dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkMilitaryTheme : AppTheme.militaryTheme,
          home: Scaffold(
            body: PersonnelMatchCard(
              item: ParsedPersonnelItem(
                rawIndex: 1,
                rawRank: 'Yb.',
                rawName: 'Ahmet',
              ),
              teamName: '1/B',
              onSelect: () {},
              onDelete: () {},
              onAddNewPerson: () {},
            ),
          ),
        ),
      );
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('bulk-person-add-new')),
      );
      final background = button.style!.backgroundColor!.resolve({})!;
      final foreground = button.style!.foregroundColor!.resolve({})!;
      expect(_contrast(foreground, background), greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
    });
  }
}
