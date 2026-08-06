import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/view_models/temgundrap_operation_draft.dart';

void main() {
  group('TEMGÜNDRAP biçimlendirme', () {
    test('tarihi askerî gösterime çevirir', () {
      expect(TemgundrapFormatters.militaryDateTime(DateTime(2026, 8, 6, 9, 15)),
          '06 0915 AGU 26');
    });
    test('telefonu tek biçime getirir', () {
      expect(TemgundrapFormatters.phone('+90 533 158 35 97'), '533 158 35 97');
      expect(TemgundrapFormatters.isValidTurkishMobile('05331583597'), isTrue);
    });
  });

  group('TemgundrapOperationDraft', () {
    late TemgundrapOperationDraft draft;
    setUp(() {
      draft = TemgundrapOperationDraft(now: DateTime(2026, 8, 6, 9, 15))
        ..operationArea = 'ELAZIĞ'
        ..commander = const CommanderSnapshot(
            personnelId: 1,
            name: 'S. TAHA BİRİNCİ',
            rank: 'J.UZM.ÇVŞ.',
            phone: '533 158 35 97')
        ..strength = const TemgundrapStrength(
            officer: 1,
            nco: 2,
            specialistGendarmerie: 3,
            specialistSergeant: 2);
    });
    tearDown(() => draft.dispose());

    test('mevcut toplamını kuvvet metnine taşır', () {
      draft.addVehicle(const TemgundrapVehicleAssignment(
          model: 'TRANSİT', plate: '23 JAA 240'));
      expect(draft.buildOperation().forceDescription,
          '(8) PERSONEL\n(1) TRANSİT\n23 JAA 240');
    });
    test('aynı plakayı ikinci kez eklemez', () {
      const vehicle =
          TemgundrapVehicleAssignment(model: 'TRANSİT', plate: '23 JAA 240');
      expect(draft.addVehicle(vehicle), isTrue);
      expect(draft.addVehicle(vehicle), isFalse);
    });
    test('bitiş başlangıçtan sonra değilse doğrulama hatası verir', () {
      draft.endAt = draft.startAt;
      expect(draft.validate(), contains('Bitiş zamanı'));
    });
  });
}
