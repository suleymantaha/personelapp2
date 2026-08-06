import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_operation_area_picker.dart';

void main() {
  test('varsayılan liste il, merkez, bütün ilçeler ve elle girişi içerir', () {
    expect(defaultTemgundrapOperationAreas, <String>[
      'ELAZIĞ İL J.K.LIĞI',
      'ELAZIĞ İL MERKEZ',
      'AĞIN İLÇE J.K.LIĞI',
      'ALACAKAYA İLÇE J.K.LIĞI',
      'ARICAK İLÇE J.K.LIĞI',
      'BASKİL İLÇE J.K.LIĞI',
      'KARAKOÇAN İLÇE J.K.LIĞI',
      'KEBAN İLÇE J.K.LIĞI',
      'KOVANCILAR İLÇE J.K.LIĞI',
      'MADEN İLÇE J.K.LIĞI',
      'PALU İLÇE J.K.LIĞI',
      'SİVRİCE İLÇE J.K.LIĞI',
      customTemgundrapOperationArea,
    ]);
  });

  testWidgets('listeden seçilen bölgeyi bildirir', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TemgundrapOperationAreaPicker(
          areas: const ['ELAZIĞ İL MERKEZ', customTemgundrapOperationArea],
          onChanged: (value) => selected = value,
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('operation-area-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ELAZIĞ İL MERKEZ').last);
    await tester.pumpAndSettle();

    expect(selected, 'ELAZIĞ İL MERKEZ');
    expect(find.byKey(const Key('operation-area-custom')), findsNothing);
  });

  testWidgets('Elle Ekle seçilince özel alan açar ve değeri bildirir',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TemgundrapOperationAreaPicker(
          areas: const [customTemgundrapOperationArea],
          onChanged: (value) => selected = value,
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('operation-area-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(customTemgundrapOperationArea).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('operation-area-custom')),
      'ELAZIĞ ÖZEL BÖLGE',
    );

    expect(selected, 'ELAZIĞ ÖZEL BÖLGE');
  });
}
