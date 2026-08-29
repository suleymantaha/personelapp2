import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';

void main() {
  testWidgets('router notifications have an Overlay for their tooltip',
      (tester) async {
    final router = createAppRouter();
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(router.dispose);
    addTearDown(database.close);
    addTearDown(() {
      if (AppNotifications.controller.current != null) {
        AppNotifications.controller.dismiss();
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    AppNotifications.warning('Önce operasyon komutanını seçin.');
    await tester.pump();

    expect(find.byKey(const Key('app-notification-card')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Bildirimi kapat'));
    await tester.pumpAndSettle();

    expect(AppNotifications.controller.current, isNull);
  });
}
