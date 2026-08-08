import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/models/dashboard_action_item.dart';

void main() {
  group('Dashboard Components & Menu Cards Widget Tests', () {
    testWidgets('DashboardMenuCard renders title, icon and responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardMenuCard(
              title: 'Personel Yönetimi',
              subtitle: 'Personel ekle/düzenle',
              icon: Icons.people,
              tone: DashboardActionTone.primary,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personel Yönetimi'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);

      await tester.tap(find.byType(DashboardMenuCard));
      expect(tapped, isTrue);
    });

    testWidgets('DashboardActionItem holds title, icon, tone and onTap callback', (WidgetTester tester) async {
      bool actionTapped = false;

      final action = DashboardActionItem(
        title: 'Nöbet Matrisi',
        subtitle: 'Çizelge',
        icon: Icons.calendar_month,
        tone: DashboardActionTone.neutral,
        onTap: () {
          actionTapped = true;
        },
      );

      expect(action.title, equals('Nöbet Matrisi'));
      action.onTap();
      expect(actionTapped, isTrue);
    });
  });
}
