import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_strength_editor.dart';

void main() {
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
