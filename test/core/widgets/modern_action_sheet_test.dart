import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';

void main() {
  testWidgets('ortak işlem paneli seçilen değeri döndürür', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () async =>
                    selected = await showModernActionSheet<String>(
                      context,
                      title: 'İşlemler',
                      icon: Icons.more_horiz,
                      options: const [
                        ModernActionOption(
                          value: 'edit',
                          title: 'Düzenle',
                          icon: Icons.edit,
                        ),
                      ],
                    ),
                child: const Text('Aç'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('İşlemler'), findsOneWidget);
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(selected, 'edit');
  });
}
