import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import '../data/team_analytics_repository.dart';
import '../domain/team_analytics.dart';

final teamAnalyticsProvider = StreamProvider.autoDispose
    .family<TeamAnalytics, AnalyticsFilter>((ref, filter) {
  final actor = ref.watch(userSessionProvider);
  final db = ref.watch(databaseProvider);
  if (actor == null) {
    return Stream.value(TeamAnalytics(filter: filter, entries: const []));
  }
  final repository = TeamAnalyticsRepository(db);
  return db
      .customSelect('SELECT 1 AS revision', readsFrom: {
        db.faaliyetPersonelAtamaTable,
        db.gunlukFaaliyetTable,
        db.personelTable,
        db.timTable,
        db.kullaniciTable,
      })
      .watch()
      .asyncMap((_) => repository.load(filter, actor));
});
