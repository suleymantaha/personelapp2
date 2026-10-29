import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';

/// Only call for synthetic fixtures whose registration team is known to be
/// their intended historical team. Never use for unknown-history test cases.
Future<void> seedTaskTeamHistory(AppDatabase db) async {
  final people = await db.select(db.personelTable).get();
  final recorded = (await db.select(db.timUyelikGecmisiTable).get())
      .map((event) => event.personelId)
      .toSet();
  for (final person in people) {
    if (recorded.contains(person.id)) continue;
    await db.into(db.timUyelikGecmisiTable).insert(
          TimUyelikGecmisiTableCompanion.insert(
            personelId: person.id,
            tarih: person.kayitTarihi,
            islem: person.timId == null ? 'çıkarıldı' : 'eklendi',
            timId: Value(person.timId),
          ),
        );
  }
}
