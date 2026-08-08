import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';

void main() {
  group('ModernActionMenu Widget Tests', () {
    testWidgets('renders ModernMenuHeader correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ModernMenuHeader<String>(
                    title: 'Test Menu',
                    subtitle: 'Sub title text',
                    icon: Icons.settings,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Menu'), findsOneWidget);
      expect(find.text('Sub title text'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('ModernActionOption holds title, icon and destructive flag', (WidgetTester tester) async {
      const option = ModernActionOption<int>(
        value: 1,
        title: 'Delete Item',
        subtitle: 'Permanent action',
        icon: Icons.delete,
        isDestructive: true,
      );

      expect(option.value, equals(1));
      expect(option.title, equals('Delete Item'));
      expect(option.isDestructive, isTrue);
    });
  });
}
