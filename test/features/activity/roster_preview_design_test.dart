import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_actions.dart';
import 'package:personelapp2/features/activity/presentation/widgets/roster_preview_rule_and_people.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('signature retry remains available after rule preview',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var loads = 0;
    final rows = [
      MilitaryRosterRow(
        sNu: 1,
        personelId: 1,
        birligi: 'Test',
        rutbe: 'J.Er',
        adSoyad: 'PERSONEL',
        diger: '',
      ),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkMilitaryTheme,
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {},
          loadSigners: () async {
            loads++;
            if (loads == 1) throw StateError('test load failure');
            return List.of(heybetRosterSigners);
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-signatures-retry')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('roster-signatures-retry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-signatures-retry')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('roster-signatures-retry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('roster-signatures-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('roster-signatures-retry')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('roster-rule-export')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('people list starts closed and opens all names on request',
      (tester) async {
    final rows = [
      for (var i = 1; i <= 4; i++)
        MilitaryRosterRow(
          sNu: i,
          personelId: i,
          birligi: 'Test',
          rutbe: 'J.Er',
          adSoyad: 'PERSONEL $i',
          diger: '',
        ),
    ];
    var expanded = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          return RosterPreviewPeople(
            rows: rows,
            showAll: expanded,
            onToggleAll: () => setState(() => expanded = !expanded),
          );
        }),
      ),
    ));

    expect(find.text('Personel listesi · 4'), findsOneWidget);
    expect(find.text('PERSONEL 1'), findsNothing);
    await tester.tap(find.byKey(const Key('roster-preview-people-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('PERSONEL 1'), findsOneWidget);
    expect(find.text('PERSONEL 4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('roster-preview-people-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('PERSONEL 1'), findsNothing);
  });

  testWidgets('two footer actions switch from rule preview to rule export',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = [
      MilitaryRosterRow(
        sNu: 1,
        personelId: 1,
        birligi: 'Test',
        rutbe: 'J.Er',
        adSoyad: 'PERSONEL',
        diger: '',
      ),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkMilitaryTheme,
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: const [],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final footer = find.byKey(const Key('roster-preview-footer'));
    expect(footer, findsOneWidget);
    expect(find.byKey(const Key('roster-export')), findsNothing);
    expect(
      find.descendant(
        of: footer,
        matching: find.byKey(const Key('roster-matrix-rule-preview')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('roster-export-rank')), findsOneWidget);
    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('roster-matrix-rule-preview')), findsNothing);
    expect(
      find.descendant(
        of: footer,
        matching: find.byKey(const Key('roster-rule-export')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('roster-export-rank')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rule preview can load before signers but export waits for them',
      (tester) async {
    Future<void> pumpActions(bool hasRulePreview, bool signaturesReady) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: RosterPreviewActions(
            hasRulePreview: hasRulePreview,
            ruleRowsEmpty: false,
            busy: false,
            signaturesReady: signaturesReady,
            onRulePreview: () {},
            onRuleExport: () {},
            onRankExport: () {},
          ),
        ),
      ));
    }

    await pumpActions(false, false);
    expect(
      tester
          .widget<FilledButton>(
              find.byKey(const Key('roster-matrix-rule-preview')))
          .onPressed,
      isNotNull,
    );
    await pumpActions(true, false);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('roster-rule-export')))
          .onPressed,
      isNull,
    );
    await pumpActions(true, true);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('roster-rule-export')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('modern preview fits a phone in dark theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cards = [
      for (var i = 0; i < 5; i++)
        GunlukFaaliyetTableData(
          id: i + 1,
          faaliyetAdi: ['HEYBET', 'Meti', 'Nöbet', 'HAZIR KITA', 'GÜLÜŞKÜR'][i],
          tarih: i < 2 ? '2026-10-28' : '2026-10-27',
          olusturanKullanici: 'test',
          olusturmaTarihi: '2026-10-28',
        ),
    ];
    final rows = [
      for (var i = 1; i <= 85; i++)
        MilitaryRosterRow(
          sNu: i,
          personelId: i,
          birligi: 'Test',
          rutbe: i == 1 ? 'J.Yb.' : 'J.Er',
          adSoyad: 'PERSONEL $i',
          diger: '',
        ),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkMilitaryTheme,
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: cards,
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Aylık matris · 1–28 Ekim 2026'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.text("Seçilen güne kadar 20 X'i aşanlar hariç"))
          .dy,
      greaterThan(tester.getBottomLeft(find.text('21+ X')).dy),
    );
    expect(find.text('İmzalar', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('edit-roster-signer-0')), findsNothing);
    expect(find.byKey(const Key('edit-roster-signer-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
