import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

double contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

Future<void> pumpHost(
  WidgetTester tester, {
  required Size size,
  required AppNotificationController controller,
  ThemeData? theme,
  TextScaler? textScaler,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler ?? TextScaler.noScaling),
        child: AppNotificationHost(
          controller: controller,
          child: const Scaffold(body: Text('İçerik')),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mobile notification is top centered', (tester) async {
    final controller = AppNotificationController();
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
    );

    controller.show(message: 'Bilgi', type: AppNotificationType.info);
    await tester.pump();

    final rect = tester.getRect(
      find.byKey(const Key('app-notification-card')),
    );
    expect(rect.top, lessThan(80));
    expect(rect.center.dx, closeTo(195, 2));
    controller.dismiss();
  });

  testWidgets('wide notification is aligned to the top right', (tester) async {
    final controller = AppNotificationController();
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(1200, 800),
      controller: controller,
    );

    controller.show(message: 'Bilgi', type: AppNotificationType.info);
    await tester.pump();

    final rect = tester.getRect(
      find.byKey(const Key('app-notification-card')),
    );
    expect(rect.top, lessThan(80));
    expect(rect.right, closeTo(1184, 2));
    controller.dismiss();
  });

  for (final typeCase in <({
    AppNotificationType type,
    IconData icon,
    String semanticLabel,
  })>[
    (
      type: AppNotificationType.success,
      icon: Icons.check_circle_rounded,
      semanticLabel: 'Başarılı',
    ),
    (
      type: AppNotificationType.error,
      icon: Icons.error_rounded,
      semanticLabel: 'Hata',
    ),
    (
      type: AppNotificationType.warning,
      icon: Icons.warning_amber_rounded,
      semanticLabel: 'Uyarı',
    ),
    (
      type: AppNotificationType.info,
      icon: Icons.info_rounded,
      semanticLabel: 'Bilgi',
    ),
  ]) {
    testWidgets('${typeCase.type.name} exposes its icon and semantic label',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = AppNotificationController();
      addTearDown(controller.dispose);
      await pumpHost(
        tester,
        size: const Size(390, 844),
        controller: controller,
      );

      controller.show(message: 'Bildirim', type: typeCase.type);
      await tester.pumpAndSettle();

      expect(find.byIcon(typeCase.icon), findsOneWidget);
      expect(
        find.bySemanticsLabel('${typeCase.semanticLabel}: Bildirim'),
        findsOneWidget,
      );
      controller.dismiss();
      semantics.dispose();
    });
  }

  testWidgets('close button dismisses the current notification',
      (tester) async {
    final controller = AppNotificationController();
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
    );
    controller.show(message: 'Kapatılabilir', type: AppNotificationType.info);
    await tester.pump();

    await tester.tap(find.byTooltip('Bildirimi kapat'));
    await tester.pumpAndSettle();

    expect(controller.current, isNull);
    expect(find.byKey(const Key('app-notification-card')), findsNothing);
  });

  testWidgets('GERİ AL invokes the notification callback once', (tester) async {
    final controller = AppNotificationController();
    var actionCalls = 0;
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
    );
    controller.show(
      message: 'Geri alınabilir',
      type: AppNotificationType.success,
      actionLabel: 'GERİ AL',
      onAction: () => actionCalls++,
    );
    await tester.pump();

    await tester.tap(find.text('GERİ AL'));
    await tester.pumpAndSettle();

    expect(actionCalls, 1);
    expect(controller.current, isNull);
  });

  testWidgets('notification uses the dark theme surface color', (tester) async {
    final controller = AppNotificationController();
    final theme = ThemeData(colorScheme: const ColorScheme.dark());
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
      theme: theme,
    );
    controller.show(message: 'Koyu tema', type: AppNotificationType.info);
    await tester.pump();

    final material = tester.widget<Material>(
      find.byKey(const Key('app-notification-card')),
    );
    expect(material.color, theme.colorScheme.surfaceContainerHigh);
    controller.dismiss();
  });

  for (final themeCase in <({String name, ThemeData theme})>[
    (name: 'light', theme: AppTheme.militaryTheme),
    (name: 'dark', theme: AppTheme.darkMilitaryTheme),
  ]) {
    for (final typeCase in <({
      AppNotificationType type,
      IconData icon,
      Color Function(AppCustomColors colors) accent,
    })>[
      (
        type: AppNotificationType.success,
        icon: Icons.check_circle_rounded,
        accent: (colors) => colors.approvedColor,
      ),
      (
        type: AppNotificationType.warning,
        icon: Icons.warning_amber_rounded,
        accent: (colors) => colors.pendingColor,
      ),
    ]) {
      testWidgets(
          '${themeCase.name} ${typeCase.type.name} meets accent and action contrast',
          (tester) async {
        final controller = AppNotificationController();
        addTearDown(controller.dispose);
        await pumpHost(
          tester,
          size: const Size(390, 844),
          controller: controller,
          theme: themeCase.theme,
        );
        controller.show(
          message: 'Kontrast',
          type: typeCase.type,
          actionLabel: 'GERİ AL',
        );
        await tester.pump();

        final surface = tester
            .widget<Material>(
              find.byKey(const Key('app-notification-card')),
            )
            .color!;
        final iconColor =
            tester.widget<Icon>(find.byIcon(typeCase.icon)).color!;
        final expectedAccent = typeCase.accent(
          themeCase.theme.extension<AppCustomColors>()!,
        );
        final accentContainer = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const Key('app-notification-card')),
                matching: find.byType(Container),
              ),
            )
            .firstWhere(
              (container) =>
                  (container.decoration as BoxDecoration?)?.border != null,
            );
        final accentBorder =
            ((accentContainer.decoration! as BoxDecoration).border! as Border)
                .left
                .color;
        final actionText = tester.renderObject<RenderParagraph>(
          find.text('GERİ AL'),
        );
        final actionColor = actionText.text.style!.color!;

        expect(accentBorder, expectedAccent);
        expect(contrastRatio(iconColor, surface), greaterThanOrEqualTo(3));
        expect(contrastRatio(actionColor, surface), greaterThanOrEqualTo(4.5));
        controller.dismiss();
      });
    }
  }

  testWidgets('host detach retains the notification until reattach',
      (tester) async {
    final controller = AppNotificationController();
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
    );
    controller.show(
      message: 'Yeniden bağlan',
      type: AppNotificationType.info,
      duration: const Duration(seconds: 1),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(controller.current?.message, 'Yeniden bağlan');

    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
    );
    await tester.pump(const Duration(seconds: 1));

    expect(controller.current, isNull);
  });

  testWidgets('host safely replaces its controller', (tester) async {
    final first = AppNotificationController();
    final second = AppNotificationController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: first,
    );
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: second,
    );

    first.show(
      message: 'Eski controller',
      type: AppNotificationType.info,
      duration: const Duration(seconds: 1),
    );
    second.show(
      message: 'Yeni controller',
      type: AppNotificationType.info,
      duration: const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(first.current?.message, 'Eski controller');
    expect(second.current, isNull);
    first.dismiss();
  });

  testWidgets('text scale 2.0 produces no overflow exception', (tester) async {
    final controller = AppNotificationController();
    addTearDown(controller.dispose);
    await pumpHost(
      tester,
      size: const Size(390, 844),
      controller: controller,
      textScaler: TextScaler.linear(2),
    );
    controller.show(
      message: 'Bu bildirim büyük metinde de taşmadan okunabilir olmalıdır.',
      type: AppNotificationType.warning,
      actionLabel: 'GERİ AL',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    controller.dismiss();
  });
}
