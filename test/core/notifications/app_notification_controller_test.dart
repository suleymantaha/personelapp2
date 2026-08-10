import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';

void main() {
  group('AppNotificationController', () {
    test('shows one notification and queues the next distinct notification',
        () {
      final controller = AppNotificationController();
      addTearDown(controller.dispose);

      controller.show(message: 'Birinci', type: AppNotificationType.info);
      controller.show(message: 'İkinci', type: AppNotificationType.success);

      expect(controller.current?.message, 'Birinci');
      controller.dismiss();
      expect(controller.current?.message, 'İkinci');
    });

    test('suppresses an equivalent current or queued notification', () {
      final controller = AppNotificationController();
      addTearDown(controller.dispose);

      controller.show(message: 'Aynı mesaj', type: AppNotificationType.warning);
      controller.show(message: 'Aynı mesaj', type: AppNotificationType.warning);
      controller.dismiss();

      expect(controller.current, isNull);
    });

    testWidgets(
        'queues matching actionable notifications unless they share a key',
        (tester) async {
      final calls = <String>[];
      final controller = AppNotificationController();
      addTearDown(controller.dispose);

      controller.show(
        message: 'Aynı işlem',
        type: AppNotificationType.info,
        actionLabel: 'GERİ AL',
        onAction: () => calls.add('first'),
      );
      controller.show(
        message: 'Aynı işlem',
        type: AppNotificationType.info,
        actionLabel: 'GERİ AL',
        onAction: () => calls.add('second'),
      );

      controller.performAction();
      await Future<void>.microtask(() {});
      controller.performAction();

      expect(calls, ['first', 'second']);

      controller.show(
        message: 'Tekrarlanan işlem',
        type: AppNotificationType.info,
        actionLabel: 'GERİ AL',
        onAction: () => calls.add('keyed-first'),
        deduplicationKey: 'same-logical-action',
      );
      controller.show(
        message: 'Tekrarlanan işlem',
        type: AppNotificationType.info,
        actionLabel: 'GERİ AL',
        onAction: () => calls.add('keyed-second'),
        deduplicationKey: 'same-logical-action',
      );

      await Future<void>.microtask(() {});
      controller.performAction();
      await Future<void>.microtask(() {});
      controller.performAction();

      expect(calls, ['first', 'second', 'keyed-first']);
    });

    testWidgets('action runs once and advances the queue even if tapped twice',
        (tester) async {
      var calls = 0;
      final controller = AppNotificationController();
      addTearDown(controller.dispose);
      controller.show(
        message: 'Silindi',
        type: AppNotificationType.info,
        actionLabel: 'GERİ AL',
        onAction: () => calls++,
      );

      controller.performAction();
      controller.performAction();

      expect(calls, 1);
    });

    testWidgets(
        'ignores a repeated action and releases the queue without a frame',
        (tester) async {
      var firstCalls = 0;
      var secondCalls = 0;
      final controller = AppNotificationController();
      addTearDown(controller.dispose);
      controller.show(
        message: 'İlk işlem',
        type: AppNotificationType.info,
        actionLabel: 'İLK',
        onAction: () => firstCalls++,
      );
      controller.show(
        message: 'İkinci işlem',
        type: AppNotificationType.warning,
        actionLabel: 'İKİNCİ',
        onAction: () => secondCalls++,
      );

      controller.performAction();
      controller.performAction();

      expect(firstCalls, 1);
      expect(secondCalls, 0);
      expect(controller.current?.message, 'İkinci işlem');

      await Future<void>.microtask(() {});
      controller.performAction();

      expect(secondCalls, 1);
    });

    testWidgets('automatically dismisses after the configured duration',
        (tester) async {
      final controller = AppNotificationController();
      addTearDown(controller.dispose);
      controller.attach();
      controller.show(
        message: 'Tamamlandı',
        type: AppNotificationType.success,
        duration: const Duration(seconds: 2),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(controller.current, isNull);
    });

    testWidgets('waits to auto-dismiss until a host is attached',
        (tester) async {
      final controller = AppNotificationController();
      addTearDown(controller.dispose);
      controller.show(
        message: 'Host bekleniyor',
        type: AppNotificationType.info,
        duration: const Duration(seconds: 1),
      );

      await tester.pump(const Duration(seconds: 2));
      expect(controller.current?.message, 'Host bekleniyor');

      controller.attach();
      await tester.pump(const Duration(seconds: 1));

      expect(controller.current, isNull);
    });

    testWidgets('pauses on last detach and restarts on reattach',
        (tester) async {
      final controller = AppNotificationController();
      addTearDown(controller.dispose);
      controller.attach();
      controller.show(
        message: 'Yaşam döngüsü',
        type: AppNotificationType.info,
        duration: const Duration(seconds: 1),
      );

      await tester.pump(const Duration(milliseconds: 500));
      controller.detach();
      await tester.pump(const Duration(seconds: 2));
      expect(controller.current?.message, 'Yaşam döngüsü');

      controller.attach();
      await tester.pump(const Duration(seconds: 1));

      expect(controller.current, isNull);
    });
  });
}
