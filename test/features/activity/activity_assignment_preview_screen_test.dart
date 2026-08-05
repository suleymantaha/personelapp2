import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';

void main() {
  const preview = ActivityAssignmentPreview(
    squadNames: {1: 'K.H', 2: '7-B Timi'},
    items: [
      ActivityAssignmentPreviewItem(
        personnelId: 1,
        name: 'Ziya KAYA',
        rank: 'J.Uzm.Çvş.',
        squadId: 1,
        duty: 'HEYBET',
        expectedStatus: AssignmentStatus.onaylandi,
        hasConflict: false,
      ),
      ActivityAssignmentPreviewItem(
        personnelId: 2,
        name: 'Ahmet YILMAZ',
        rank: 'J.Bnb.',
        squadId: 1,
        duty: 'HEYBET',
        expectedStatus: AssignmentStatus.onaylandi,
        hasConflict: false,
      ),
      ActivityAssignmentPreviewItem(
        personnelId: 3,
        name: 'Mehmet DEMİR',
        rank: 'J.Asb.',
        squadId: 2,
        duty: 'NÖBETÇİ',
        expectedStatus: AssignmentStatus.beklemede,
        hasConflict: true,
      ),
    ],
  );

  Widget subject({Future<bool> Function()? onConfirm}) => MaterialApp(
        theme: AppTheme.militaryTheme,
        home: ActivityAssignmentPreviewScreen(
          activityName: 'Heybet Tepe',
          date: DateTime(2026, 8, 6),
          preview: preview,
          requiresAdminApproval: false,
          onConfirm: onConfirm ?? () async => false,
        ),
      );

  testWidgets('shows closed team cards, summaries and ordered personnel',
      (tester) async {
    await tester.pumpWidget(subject());

    expect(find.text('Heybet Tepe'), findsOneWidget);
    expect(find.text('3 personel'), findsOneWidget);
    expect(find.text('2 tim'), findsOneWidget);
    expect(find.text('1 uyarı'), findsNWidgets(2));
    expect(find.text('K.H • 2 kişi • 2 HEYBET'), findsOneWidget);
    expect(find.byKey(const Key('preview-person-1')), findsNothing);

    await tester.tap(find.byKey(const Key('preview-team-header-1')));
    await tester.pump();
    expect(find.byKey(const Key('preview-person-1')), findsOneWidget);
    expect(find.byKey(const Key('preview-person-2')), findsOneWidget);
    expect(
      tester.getTopLeft(find.textContaining('Ahmet YILMAZ')).dy,
      lessThan(tester.getTopLeft(find.textContaining('Ziya KAYA')).dy),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('preview-team-header-2')),
      300,
    );
    await tester.tap(find.byKey(const Key('preview-team-header-2')));
    await tester.pump();
    expect(find.byKey(const Key('preview-person-1')), findsNothing);
    expect(find.text('Kaydedilmeyecek'), findsOneWidget);
  });

  testWidgets('disables confirmation while save is running', (tester) async {
    final completer = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(subject(onConfirm: () {
      calls++;
      return completer.future;
    }));

    await tester.tap(find.byKey(const Key('preview-confirm-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('preview-confirm-button')));
    expect(calls, 1);
    expect(find.text('Kaydediliyor…'), findsOneWidget);

    completer.complete(false);
    await tester.pump();
    expect(find.text('Onayla ve Kaydet'), findsOneWidget);
  });

  testWidgets('stays usable on a narrow phone with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 760)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: subject(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('preview-confirm-button')), findsOneWidget);
  });
}
