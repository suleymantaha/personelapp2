import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/team_activity_card.dart';

void main() {
  group('TeamActivityCard Aggregate Root', () {
    test('should reject creation when teamId or teamName is empty', () {
      final result1 = TeamActivityCard.create(
        teamId: null,
        teamName: '1-A Timi',
        date: '2026-08-09',
        activityType: 'Nöbet',
        assignments: [],
      );

      expect(result1.isSuccess, isFalse);
      expect(result1.error, contains('Tim kimliği ve adı zorunludur'));

      final result2 = TeamActivityCard.create(
        teamId: 1,
        teamName: '   ',
        date: '2026-08-09',
        activityType: 'Nöbet',
        assignments: [],
      );

      expect(result2.isSuccess, isFalse);
      expect(result2.error, contains('Tim kimliği ve adı zorunludur'));
    });

    test('should successfully create TeamActivityCard when invariants are satisfied', () {
      final result = TeamActivityCard.create(
        teamId: 5,
        teamName: '5-B Timi',
        date: '2026-08-09',
        activityType: 'Nöbet',
        assignments: ['P1', 'P2'],
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!.teamId, equals(5));
      expect(result.value!.teamName, equals('5-B Timi'));
      expect(result.value!.id, equals('2026-08-09_5'));
    });
  });
}
