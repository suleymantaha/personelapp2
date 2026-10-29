import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/services/task_team_repair_sequences.dart';

void main() {
  test('sequence limits preserve exact integers on native and JavaScript', () {
    const table = 'faaliyet_personel_atama_table';
    const payload = <String, Object?>{'tables': <String, Object?>{}};
    expect(TaskTeamRepairSequences.parse({table: 9007199254740991}, payload),
        {table: 9007199254740991});
    expect(() => TaskTeamRepairSequences.parse({table: 9007199254740992}, payload),
        throwsFormatException);
    expect(() => TaskTeamRepairSequences.parse({table: -1}, payload),
        throwsFormatException);
  });
}
