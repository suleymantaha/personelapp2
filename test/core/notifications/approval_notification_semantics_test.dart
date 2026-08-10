import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';

void main() {
  testWidgets('approval result exposes completed and pending semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = AppNotifications.controller;
    while (controller.current != null) {
      controller.dismiss();
    }
    addTearDown(() {
      while (controller.current != null) {
        controller.dismiss();
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: AppNotificationHost(
          controller: controller,
          child: const Scaffold(body: Text('İçerik')),
        ),
      ),
    );

    AppNotifications.approvalResult(
      'İşlem tamamlandı.',
      pendingApproval: false,
    );
    await tester.pumpAndSettle();

    expect(controller.current?.type, AppNotificationType.success);
    expect(
      find.bySemanticsLabel('Başarılı: İşlem tamamlandı.'),
      findsOneWidget,
    );

    controller.dismiss();
    await tester.pumpAndSettle();
    AppNotifications.approvalResult(
      'Admin onayına gönderildi.',
      pendingApproval: true,
    );
    await tester.pumpAndSettle();

    expect(controller.current?.type, AppNotificationType.warning);
    expect(
      find.bySemanticsLabel('Uyarı: Admin onayına gönderildi.'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
