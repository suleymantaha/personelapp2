import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

void main() {
  for (final changed in [false, true]) {
    testWidgets('preview image save reloads rows, changed=$changed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('nizam/backup_files');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var saves = 0, reloads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        saves++;
        expect((call.arguments as Map)['mimeType'], 'image/png');
        return true;
      });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(channel, null);
        while (AppNotifications.controller.current != null) {
          AppNotifications.controller.dismiss();
        }
      });
      final rows = [
        MilitaryRosterRow(
            sNu: 1,
            birligi: 'Test',
            rutbe: 'Test',
            adSoyad: 'Örnek Personel',
            diger: '')
      ];
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        home: RosterOutputPreviewScreen(
            date: '2026-10-25',
            sources: const [],
            rows: rows,
            loadRows: () async {
              reloads++;
              return changed ? [] : rows;
            }),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roster-export-rank')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Uzun görsel olarak kaydet'));
      await tester.tap(find.text('Uzun görsel olarak kaydet'));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && saves == 0 && !changed; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(reloads, 1);
      expect(saves, changed ? 0 : 1);
      if (changed) expect(find.textContaining('değişti'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
