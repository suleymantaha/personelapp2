import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';

class MatrixRepository {
  MatrixRepository(this.db);

  final AppDatabase db;

  /// Returns a stream mapping personnelId to a map of (dayNumber -> dutyStatusString) for a given yearMonth ("YYYY-MM").
  Stream<Map<int, Map<int, String>>> watchMonthlyMatrix(String yearMonth) {
    final query = db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ])..where(db.gunlukFaaliyetTable.tarih.like('$yearMonth%'));

    return query.watch().map((rows) {
      final matrixMap = <int, Map<int, String>>{};
      for (final row in rows) {
        final atama = row.readTable(db.faaliyetPersonelAtamaTable);
        final faaliyet = row.readTable(db.gunlukFaaliyetTable);

        // Date format: "YYYY-MM-DD"
        final dateParts = faaliyet.tarih.split('-');
        if (dateParts.length < 3) continue;

        final day = int.tryParse(dateParts[2]);
        if (day == null) continue;

        final pMap = matrixMap.putIfAbsent(atama.personelId, () => {});
        final status = atama.durum == 'beklemede'
            ? '${atama.gorevVeyaIzin} (beklemede)'
            : atama.gorevVeyaIzin;

        pMap[day] = status;
      }
      return matrixMap;
    });
  }
}
