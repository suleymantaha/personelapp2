import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/view_models/temgundrap_operation_draft.dart';

void main() {
  test('kayıtlı operasyon düzenleme taslağı tüm alanları korur', () {
    final initial = TemgundrapOperation(
      id: 'same-id',
      issuingUnit: 'BİRLİK',
      operationArea: 'ELAZIĞ İL MERKEZ',
      commander: const CommanderSnapshot(
        personnelId: 4,
        name: 'KOMUTAN',
        rank: 'J.Ütğm.',
        phone: '532 111 22 33',
      ),
      strength: const TemgundrapStrength(officer: 1),
      vehicles: const [
        TemgundrapVehicleAssignment(model: 'TRANSİT', plate: '23 JAA 240'),
      ],
      startAt: DateTime(2026, 8, 6, 9),
      endAt: DateTime(2026, 8, 6, 10),
      purpose: 'GÖREVLENDİRME',
      description: 'İlk açıklama',
    );
    final draft = TemgundrapOperationDraft(initial: initial);
    draft.description = 'Düzenlendi';
    final updated = draft.buildOperation(id: initial.id);
    expect(updated.id, initial.id);
    expect(updated.commander.personnelId, 4);
    expect(updated.vehicles.single.plate, '23 JAA 240');
    expect(updated.description, 'Düzenlendi');
  });
}
