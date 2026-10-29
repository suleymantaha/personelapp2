import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const session = UserSessionState(username: 'admin', role: UserRole.admin);

  testWidgets(
      'restoring confirmation after its form closes safely returns home',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    final router = createAppRouter(session: session);
    addTearDown(router.dispose);
    addTearDown(db.close);
    var formActive = true;
    var confirmations = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        userSessionProvider.overrideWith((ref) => session)
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    router.push<void>(AppRoutes.activityAssignmentPreview,
        extra: ActivityAssignmentPreviewArgs(
          activityName: 'Synthetic activity',
          date: DateTime(2026, 10, 29),
          preview: const ActivityAssignmentPreview(items: [], squadNames: {}),
          requiresAdminApproval: false,
          isActive: () => formActive,
          onConfirm: () async {
            confirmations++;
            return true;
          },
        ));
    await tester.pumpAndSettle();
    final info = router.routeInformationParser
        .restoreRouteInformation(router.routerDelegate.currentConfiguration)!;
    router.go(AppRoutes.dashboard);
    await tester.pumpAndSettle();
    formActive = false;
    router.routeInformationProvider.didPushRouteInformation(RouteInformation(
        uri: info.uri, state: jsonDecode(jsonEncode(info.state))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ActivityAssignmentPreviewScreen), findsNothing);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.dashboard);
    expect(confirmations, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('router codec retains callbacks across JSON history round trips', () {
    final router = createAppRouter(session: session);
    addTearDown(router.dispose);
    final args = RosterOutputPreviewArgs(
      date: '2026-10-29',
      sources: const [],
      rows: const [],
      loadRows: () async => [],
    );
    final codec = router.configuration.extraCodec;
    expect(codec, isNotNull);
    final encoded = jsonDecode(jsonEncode(codec!.encode(args)));
    expect(codec.decode(encoded), same(args));
  });

  for (final expired in [false, true]) {
    testWidgets('history restore with expired=$expired never casts null',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase(NativeDatabase.memory());
      final router = createAppRouter(session: session);
      addTearDown(router.dispose);
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) => session)
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      final args = RosterOutputPreviewArgs(
        date: '2026-10-29',
        sources: const [],
        rows: const [],
        loadRows: () async => [],
      );
      router.push<void>(AppRoutes.rosterOutputPreview, extra: args);
      await tester.pumpAndSettle();
      final info = router.routeInformationParser.restoreRouteInformation(
        router.routerDelegate.currentConfiguration,
      )!;
      // JSON mimics the browser boundary; an old process cannot resolve tokens.
      final state = jsonDecode(jsonEncode(info.state)) as Map<String, dynamic>;
      if (expired) {
        final matches = state['imperativeMatches'] as List<dynamic>;
        (matches.last as Map<String, dynamic>)['state'] = {
          'codec': 'custom',
          'encoded': 'missing-session-token',
        };
      }
      router.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();
      router.routeInformationProvider.didPushRouteInformation(
        RouteInformation(uri: info.uri, state: state),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (expired) {
        expect(router.routerDelegate.currentConfiguration.uri.path,
            AppRoutes.rosterOutput);
      } else {
        expect(find.byType(RosterOutputPreviewScreen), findsOneWidget);
        expect(
            tester
                .widget<RosterOutputPreviewScreen>(
                    find.byType(RosterOutputPreviewScreen))
                .loadRows,
            same(args.loadRows));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
