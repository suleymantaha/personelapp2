import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_commander_picker.dart';

void main() {
  testWidgets(
      'komutan seçilince kayıtlı telefonu getirir ve anlık görüntü üretir',
      (tester) async {
    CommanderSnapshot? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TemgundrapCommanderPicker(
      options: const [
        TemgundrapCommanderOption(
            id: 7,
            name: 'S. TAHA BİRİNCİ',
            rank: 'J.UZM.ÇVŞ.',
            phone: '05331583597')
      ],
      onChanged: (value) => selected = value,
    ))));
    await tester.tap(find.byKey(const Key('commander-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J.UZM.ÇVŞ. S. TAHA BİRİNCİ').last);
    await tester.pumpAndSettle();
    final phoneField = tester.widget<TextFormField>(
      find.byKey(const Key('commander-phone')),
    );
    expect(phoneField.controller?.text, '533 158 35 97');
    expect(selected?.phone, '533 158 35 97');
    expect(selected?.personnelId, 7);
  });
}
