import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/team_analytics.dart';

class AnalyticsDetails extends StatelessWidget {
  const AnalyticsDetails({super.key, required this.data});
  final TeamAnalytics data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ids = data.entries
        .map((e) => e.teamId)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => (data.teams[a] ?? '').compareTo(data.teams[b] ?? ''));

    if (ids.isEmpty && data.unknownEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Açılımı yapılacak görev detayı bulunamadı.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.account_tree_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tim ve Personel Görev Detay Açılımı',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final id in ids) _teamCard(context, id, isDark),
        if (data.unknownEntries.isNotEmpty) _unknownEntriesCard(context, isDark),
      ],
    );
  }

  Widget _teamCard(BuildContext context, int id, bool isDark) {
    final theme = Theme.of(context);
    final teamSlice = data.forTeam(id);
    final teamName = data.teams[id] ?? 'Tim #$id';
    final m = teamSlice.metrics;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('analytics-team-$id'),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shield_rounded,
                  color: theme.colorScheme.primary, size: 22),
            ),
            title: Text(
              teamName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              '${m.participations} Katılım · ${m.dutyDays} Gün · ${m.uniquePersonnel} Kişi · ${m.personnelTasks} Personel–Görev',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              for (final duty in teamSlice.duties) _duty(context, id, duty, isDark),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _duty(BuildContext context, int team, String duty, bool isDark) {
    final theme = Theme.of(context);
    final slice = data.forTeam(team).forDuty(duty);
    final m = slice.metrics;
    final dates = slice.entries.expand((e) => e.coveredDates).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('analytics-duty-$team-$duty'),
            leading: const Icon(Icons.military_tech_outlined,
                color: Color(0xFFD97706), size: 20),
            title: Text(
              duty,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${m.participations} Katılım · ${m.dutyDays} Gün · ${m.uniquePersonnel} Kişi',
              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            children: [
              for (final date in dates)
                _date(context, team, duty, date, slice.entries, isDark),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _date(
    BuildContext context,
    int team,
    String duty,
    String date,
    List<AnalyticsEntry> entries,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final day = entries.where((e) => e.coveredDates.contains(date)).toList();
    final activities = day.map((e) => e.activityId).toSet();

    String formattedDate;
    try {
      final parsed = DateTime.parse(date);
      formattedDate = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(parsed);
    } catch (_) {
      formattedDate = date;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('analytics-date-$team-$duty-$date'),
            dense: true,
            leading: const Icon(Icons.event_outlined, size: 18, color: Color(0xFF2563EB)),
            title: Text(
              formattedDate,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              '${activities.length} Faaliyet',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              for (final id in activities)
                _activity(context, team, duty, date, id, day, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activity(
    BuildContext context,
    int team,
    String duty,
    String date,
    int id,
    List<AnalyticsEntry> day,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final entries = day.where((e) => e.activityId == id).toList();
    final source = entries.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('analytics-activity-$team-$duty-$date-$id'),
            dense: true,
            leading: const Icon(Icons.assignment_outlined, size: 18),
            title: Text(
              source.activityName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
            subtitle: Text(
              '${entries.length} Personel · Durum: ${source.status}'
              '${source.sourceDate == date ? '' : ' · Başlangıç: ${source.sourceDate}'}',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
            children: [
              for (final entry in entries)
                ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      entry.personnelName.isNotEmpty
                          ? entry.personnelName[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.personnelName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  subtitle: Text(
                    entry.duty,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5D36).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.status,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5D36),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unknownEntriesCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: isDark ? const Color(0xFF332A15) : const Color(0xFFFEF3C7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFF59E0B)),
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.help_outline_rounded, color: Color(0xFFD97706)),
          title: const Text(
            'Timi Bilinmeyen Geçmiş Atamalar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          subtitle: const Text(
            'Timi eşleşmeyen kayıtlar tim toplamlarına dahil edilmemiştir.',
            style: TextStyle(fontSize: 11.5),
          ),
          children: [
            for (final entry in data.unknownEntries)
              ListTile(
                dense: true,
                title: Text('${entry.sourceDate} · ${entry.duty}'),
                subtitle: Text(
                  '${entry.activityName} · ${entry.personnelName}\n${entry.teamName}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
