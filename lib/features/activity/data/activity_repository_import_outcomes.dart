part of 'activity_repository.dart';

typedef _ImportDecision = ({
  PersonnelAssignmentInput assignment,
  ActivityImportStatus status,
});

extension ActivityRepositoryImportOutcomes on ActivityRepository {
  Future<List<ActivityImportOutcome>> _buildImportOutcomes({
    required String activityName,
    required String date,
    required List<_ImportDecision> decisions,
    int? targetActivityId,
  }) async {
    if (decisions.isEmpty) return const [];
    final personnelIds = decisions.map((d) => d.assignment.personnelId).toSet();
    final people = await (db.select(db.personelTable)
          ..where((t) => t.id.isIn(personnelIds)))
        .get();
    final byId = {for (final person in people) person.id: person};
    final needsDescription =
        decisions.any((d) => d.status != ActivityImportStatus.added);
    final rows = needsDescription
        ? await (db.select(db.faaliyetPersonelAtamaTable).join([
            innerJoin(
                db.gunlukFaaliyetTable,
                db.gunlukFaaliyetTable.id
                    .equalsExp(db.faaliyetPersonelAtamaTable.faaliyetId)),
          ])
              ..where(
                  db.faaliyetPersonelAtamaTable.personelId.isIn(personnelIds)))
            .get()
        : const <TypedResult>[];
    final reports = needsDescription
        ? await (db.select(db.raporKayitTable)
              ..where((t) => t.personelId.isIn(personnelIds)))
            .get()
        : <RaporKayitTableData>[];
    return decisions.map((decision) {
      final input = decision.assignment;
      final person = byId[input.personnelId];
      final descriptions = <String>[];
      if (decision.status != ActivityImportStatus.added) {
        for (final row in rows) {
          final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
          final activity = row.readTable(db.gunlukFaaliyetTable);
          final isTargetRecord = activity.id == targetActivityId;
          if (assignment.personelId == input.personnelId &&
              (isTargetRecord ||
                  (assignment.durum != AssignmentStatus.reddedildi &&
                      DutyCoverage.overlaps(
                        firstDate: activity.tarih,
                        firstDuty: assignment.gorevVeyaIzin,
                        secondDate: date,
                        secondDuty: input.duty.trim(),
                      )))) {
            descriptions
                .add('${activity.faaliyetAdi} • ${assignment.gorevVeyaIzin}');
          }
        }
        final dates =
            DutyCoverage.coveredDates(startDate: date, duty: input.duty.trim());
        for (final report in reports) {
          if (report.personelId == input.personnelId &&
              dates.any((d) =>
                  d.compareTo(report.raporBaslangic) >= 0 &&
                  d.compareTo(report.raporBitis) <= 0)) {
            descriptions.add(
                'Rapor • ${report.raporBaslangic} - ${report.raporBitis}'
                '${report.aciklama?.trim().isNotEmpty == true ? ' • ${report.aciklama}' : ''}');
          }
        }
      }
      return ActivityImportOutcome(
        personnelId: input.personnelId,
        name: person?.adSoyad ?? 'Personel #${input.personnelId}',
        rank: person?.rutbe ?? '',
        activityName: activityName,
        date: date,
        duty: input.duty.trim(),
        status: decision.status,
        existingDescription:
            descriptions.isEmpty ? null : descriptions.join(' | '),
      );
    }).toList();
  }
}
