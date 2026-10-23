import 'package:flutter/material.dart';
import '../domain/team_analytics.dart';
import 'team_report_details.dart';

class TeamAnalyticsNotice extends StatelessWidget {
  const TeamAnalyticsNotice({super.key, required this.data});
  final TeamAnalytics data;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (data.duplicateAssignments > 0 || data.possibleDuplicateActivities > 0)
        Card(
            child: ExpansionTile(
          key: const ValueKey('analytics-record-checks'),
          title: const Text('Kayıt kontrolleri'),
          children: [
            ListTile(
                title: Text(
                    '${data.duplicateAssignments} tekrarlanan atama tekilleştirildi. '
                    '${data.possibleDuplicateActivities} olası mükerrer faaliyet ayrı tutuldu.'))
          ],
        )),
      if (data.unknownEntries.isNotEmpty)
        Card(
            child: ListTile(
          key: const ValueKey('analytics-unknown-teams'),
          leading: const Icon(Icons.info_outline_rounded),
          title:
              Text('${data.unknownTeamAssignments} atamanın tim bilgisi eksik'),
          subtitle: const Text('Nedenini ve kayıtları görüntüle'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showTeamReportDetails(context,
              title: 'Timi belirlenemeyen atamalar',
              explanation: 'Görev tarihindeki tim bilgisi kayıtlı değil. '
                  'Güncel tim bilgisi geçmişe uygulanmaz.',
              data: TeamAnalytics(
                  filter: data.filter, entries: data.unknownEntries)),
        )),
    ]);
  }
}
