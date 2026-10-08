import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppCard & Core Surface Primitives', () {
    testWidgets('AppCard renders child with standard border and responds to onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildTestApp(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('İçerik'),
          ),
        ),
      );
      expect(find.text('İçerik'), findsOneWidget);
      await tester.tap(find.text('İçerik'));
      expect(tapped, isTrue);
    });

    testWidgets('AppCard isolates trailing action from card onTap', (tester) async {
      var cardTapped = false;
      var actionTapped = false;

      await tester.pumpWidget(
        _buildTestApp(
          AppCard(
            onTap: () => cardTapped = true,
            trailingAction: IconButton(
              key: const Key('action-btn'),
              icon: const Icon(Icons.more_horiz),
              onPressed: () => actionTapped = true,
            ),
            child: const Text('Metin'),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('action-btn')));
      expect(actionTapped, isTrue);
      expect(cardTapped, isFalse);
    });

    testWidgets('AppEmptyState displays icon, title, description and optional action', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        _buildTestApp(
          AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Kayıt Yok',
            description: 'Listelenecek kayıt bulunamadı.',
            action: ElevatedButton(
              onPressed: () => actionTriggered = true,
              child: const Text('Ekle'),
            ),
          ),
        ),
      );

      expect(find.text('Kayıt Yok'), findsOneWidget);
      expect(find.text('Listelenecek kayıt bulunamadı.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);

      await tester.tap(find.text('Ekle'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState displays error title, message and localized retry button', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _buildTestApp(
          AppErrorState(
            title: 'Yükleme Hatası',
            error: 'Bağlantı koptu',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Yükleme Hatası'), findsOneWidget);
      expect(find.text('Bağlantı koptu'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(retried, isTrue);
    });

    testWidgets('AppNoticeBanner displays message with correct icon', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppNoticeBanner(
            message: 'Önemli bilgilendirme metni',
            icon: Icons.info_outline,
          ),
        ),
      );

      expect(find.text('Önemli bilgilendirme metni'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
