import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_strength_editor.dart';

void main() {
  testWidgets('sıfır mevcut değeri silinecek metin yerine ipucu gösterir',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TemgundrapStrengthEditor(
          value: const TemgundrapStrength(),
          onChanged: (_) {},
        ),
      ),
    ));

    final fieldFinder = find.byKey(const Key('strength-SB'));
    final editable = tester.widget<EditableText>(
      find.descendant(of: fieldFinder, matching: find.byType(EditableText)),
    );
    final decorator = tester.widget<InputDecorator>(
      find.descendant(of: fieldFinder, matching: find.byType(InputDecorator)),
    );

    expect(editable.controller.text, isEmpty);
    expect(decorator.decoration.hintText, '0');
  });

  testWidgets('dolu mevcut değeri odaklanınca tamamen seçer', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TemgundrapStrengthEditor(
          value: const TemgundrapStrength(officer: 12),
          onChanged: (_) {},
        ),
      ),
    ));

    final fieldFinder = find.byKey(const Key('strength-SB'));
    await tester.tap(fieldFinder);
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.descendant(of: fieldFinder, matching: find.byType(EditableText)),
    );
    expect(editable.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 2));
  });

  testWidgets('rütbe sayısı değişince toplamı günceller', (tester) async {
    var value = const TemgundrapStrength();
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      return Scaffold(
          body: TemgundrapStrengthEditor(
              value: value, onChanged: (next) => setState(() => value = next)));
    })));
    await tester.enterText(find.byKey(const Key('strength-SB')), '3');
    await tester.pump();
    expect(find.text('TOPLAM: 3'), findsOneWidget);
  });
}
