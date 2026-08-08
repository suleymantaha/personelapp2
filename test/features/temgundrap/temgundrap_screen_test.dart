import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('formdan dönünce setState hatası vermeden listeyi yeniler',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      initialLocation: '/temgundrap',
      routes: [
        GoRoute(
          path: '/temgundrap',
          builder: (_, __) => const TemgundrapScreen(),
        ),
        GoRoute(
          path: '/temgundrap/form',
          builder: (context, _) => Scaffold(
            body: FilledButton(
              key: const Key('close-form-as-changed'),
              onPressed: () => context.pop(true),
              child: const Text('Kaydet'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('YENİ ÇİZELGE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('close-form-as-changed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Bu güne ait taslak çizelge yok'), findsOneWidget);
  });

  testWidgets('taslak çizelge arşivlenir ve arşiv bölümünde gösterilir',
      (tester) async {
    final now = DateTime.now();
    final document = TemgundrapDocument(
      id: 'draft-1',
      date: DateTime(now.year, now.month, now.day),
      unitTitle: 'Test Birliği',
      approverName: '',
      approverRank: '',
      approverDuty: '',
      operations: const [],
      isDraft: true,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'temgundrap_documents_v1': jsonEncode([document.toJson()]),
    });
    final router = GoRouter(
      initialLocation: '/temgundrap',
      routes: [
        GoRoute(
          path: '/temgundrap',
          builder: (_, __) => const TemgundrapScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.byKey(const Key('temgundrap-document-draft-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('temgundrap-actions-draft-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Arşivle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('temgundrap-document-draft-1')), findsNothing);

    await tester.tap(find.byKey(const Key('temgundrap-archive-tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.byKey(const Key('temgundrap-document-draft-1')), findsOneWidget);
    expect(find.text('ARŞİVDE'), findsOneWidget);
  });
}
