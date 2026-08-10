import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';

void main() {
  group('ActivityFormDraft', () {
    late ActivityFormDraft draft;

    setUp(() {
      draft = ActivityFormDraft(initialDate: DateTime(2026, 8, 7));
    });

    test('starts at personnel selection and cannot continue empty', () {
      expect(draft.step, ActivityFormStep.personnelSelection);
      expect(draft.selectedCount, 0);
      expect(draft.canContinue, isFalse);
      expect(draft.canPreview, isFalse);
      expect(draft.isDirty, isFalse);
    });

    test('selects individuals and toggles a whole squad without duplicates',
        () {
      draft.togglePersonnel(1);
      draft.toggleSquad(const [1, 2, 3]);

      expect(draft.selectedPersonnelIds, {1, 2, 3});
      expect(draft.selectedCount, 3);
      expect(draft.isSquadSelected(const [1, 2, 3]), isTrue);

      draft.toggleSquad(const [1, 2, 3]);
      expect(draft.selectedPersonnelIds, isEmpty);
    });

    test('keeps personnel selections while moving between steps', () {
      draft.toggleSquad(const [1, 2, 3]);

      expect(draft.goToDetails(), isTrue);
      expect(draft.step, ActivityFormStep.activityDetails);

      draft.goToPersonnelSelection();
      expect(draft.step, ActivityFormStep.personnelSelection);
      expect(draft.selectedPersonnelIds, {1, 2, 3});
    });

    test('does not move to details without a personnel selection', () {
      expect(draft.goToDetails(), isFalse);
      expect(draft.step, ActivityFormStep.personnelSelection);
    });

    test('applies a common duty and preserves personnel overrides', () {
      draft.toggleSquad(const [1, 2, 3]);
      draft.setActivityName('Heybet');
      draft.setCommonDuty('HEYBET');
      draft.setDutyOverride(2, 'HEYBET KOMUTANI');

      expect(draft.dutyFor(1), 'HEYBET');
      expect(draft.dutyFor(2), 'HEYBET KOMUTANI');
      expect(draft.dutyFor(3), 'HEYBET');
      expect(draft.resolvedDuties, {
        1: 'HEYBET',
        2: 'HEYBET KOMUTANI',
        3: 'HEYBET',
      });
      expect(draft.canPreview, isTrue);
    });

    test('assigns a duty to one squad without affecting other personnel', () {
      draft.toggleSquad(const [1, 2, 3]);
      draft.setCommonDuty('GENEL GÖREV');

      draft.setDutyForPersonnel(const [1, 2], 'HAZIR KITA');

      expect(draft.dutyFor(1), 'HAZIR KITA');
      expect(draft.dutyFor(2), 'HAZIR KITA');
      expect(draft.dutyFor(3), 'GENEL GÖREV');

      draft.setDutyOverride(2, 'NÖBETÇİ');
      expect(draft.dutyFor(1), 'HAZIR KITA');
      expect(draft.dutyFor(2), 'NÖBETÇİ');
    });

    test('returns a squad to the common duty in one operation', () {
      draft.toggleSquad(const [1, 2]);
      draft.setCommonDuty('GENEL GÖREV');
      draft.setDutyForPersonnel(const [1, 2], 'HAZIR KITA');

      draft.setDutyForPersonnel(const [1, 2], null);

      expect(draft.dutyFor(1), 'GENEL GÖREV');
      expect(draft.dutyFor(2), 'GENEL GÖREV');
      expect(draft.dutyOverrides, isEmpty);
    });

    test('removes stale override and note when personnel is unselected', () {
      draft.togglePersonnel(7);
      draft.setCommonDuty('GÖREVLİ');
      draft.setDutyOverride(7, 'NÖBETÇİ');
      draft.setNote(7, 'Gece vardiyası');

      draft.togglePersonnel(7);

      expect(draft.selectedPersonnelIds, isEmpty);
      expect(draft.dutyOverrides, isEmpty);
      expect(draft.notes, isEmpty);
      expect(draft.resolvedDuties, isEmpty);
    });

    test('requires activity and a duty for every selected personnel', () {
      draft.togglePersonnel(1);
      draft.setActivityName('Devriye');

      expect(draft.canPreview, isFalse);

      draft.setDutyOverride(1, 'GÖREVLİ');
      expect(draft.canPreview, isTrue);
    });

    group('task card drafts', () {
      test('creates a dated duty card without auto-selecting the squad', () {
        draft.toggleSquad(const [1, 2, 3]);

        final card = draft.createTaskCard(
          date: DateTime(2026, 8, 9, 16, 30),
          duty: ' Heybet ',
        );

        expect(card.date, DateTime(2026, 8, 9));
        expect(card.duty, 'Heybet');
        expect(card.personnelIds, isEmpty);
        expect(draft.taskCards, [card]);
        expect(draft.selectedPersonnelIds, {1, 2, 3});
      });

      test('moves a personnel assignment from one duty card to another', () {
        final first = draft.createTaskCard(
          date: DateTime(2026, 8, 7),
          duty: 'HEYBET',
        );
        final second = draft.createTaskCard(
          date: DateTime(2026, 8, 7),
          duty: 'HAZIR KITA',
        );

        draft.assignPersonnelToTaskCard(first.id, 7);
        draft.assignPersonnelToTaskCard(second.id, 7);

        expect(first.personnelIds, isEmpty);
        expect(second.personnelIds, {7});
        expect(draft.selectedPersonnelIds, {7});
        expect(draft.resolvedDuties, {7: 'HAZIR KITA'});
      });

      test('removes card personnel from resolved save assignments', () {
        final card = draft.createTaskCard(
          date: DateTime(2026, 8, 7),
          duty: 'GÖREVLİ',
        );
        draft.assignPersonnelToTaskCard(card.id, 1);
        draft.assignPersonnelToTaskCard(card.id, 2);
        draft.setNote(1, 'Gece');

        draft.removePersonnelFromTaskCard(card.id, 1);

        expect(card.personnelIds, {2});
        expect(draft.selectedPersonnelIds, {2});
        expect(draft.notes, isNot(contains(1)));
        expect(draft.resolvedDuties, {2: 'GÖREVLİ'});
        expect(
          draft.resolvedPersonnelAssignments.map(
            (assignment) => (assignment.personnelId, assignment.duty),
          ),
          [(2, 'GÖREVLİ')],
        );
      });
    });
  });
}
