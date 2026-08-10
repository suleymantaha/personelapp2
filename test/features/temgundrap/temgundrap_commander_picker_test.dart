import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_commander_picker.dart';
import 'package:personelapp2/features/temgundrap/services/device_contact_picker.dart';

class _FakeContactPicker implements DeviceContactPicker {
  @override
  Future<List<String>> pickPhoneNumbers() async => ['0532 111 22 33'];
}

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('J.UZM.ÇVŞ. S. TAHA BİRİNCİ').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final phoneField = tester.widget<TextFormField>(
      find.byKey(const Key('commander-phone')),
    );
    expect(phoneField.controller?.text, '533 158 35 97');
    expect(selected?.phone, '533 158 35 97');
    expect(selected?.personnelId, 7);
  });

  testWidgets('rehberden seçilen telefonu personele öğretir', (tester) async {
    CommanderSnapshot? selected;
    int? learnedId;
    String? learnedPhone;
    await tester.pumpWidget(MaterialApp(
      home: AppNotificationHost(
        child: Scaffold(
          body: TemgundrapCommanderPicker(
            options: const [
              TemgundrapCommanderOption(
              id: 9,
              name: 'MEHMET CEYLAN',
              rank: 'J.Ütğm.',
            ),
          ],
          contactPicker: _FakeContactPicker(),
          onChanged: (value) => selected = value,
          onPhoneLearned: (id, phone) async {
            learnedId = id;
            learnedPhone = phone;
            },
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('commander-picker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('J.Ütğm. MEHMET CEYLAN').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pick-commander-contact')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(selected?.phone, '532 111 22 33');
    expect(learnedId, 9);
    expect(learnedPhone, '532 111 22 33');
    expect(find.text('Telefon personelle eşleştirildi.'), findsOneWidget);
    await tester.tap(find.byTooltip('Bildirimi kapat'));
    await tester.pumpAndSettle();
  });
}
