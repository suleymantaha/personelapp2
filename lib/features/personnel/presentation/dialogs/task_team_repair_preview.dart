import 'package:flutter/material.dart';
import 'package:personelapp2/core/services/task_team_repair_service.dart';

class TaskTeamRepairPreviewContent extends StatelessWidget {
  const TaskTeamRepairPreviewContent({required this.preview, super.key});
  final TaskTeamRepairPreview preview;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Yalnız güvenilir tarihçesi bulunan boş görev timleri doldurulur. '
              'Dolu alanlar ve belirsiz kayıtlar korunur. Henüz hiçbir veri değiştirilmedi.'),
          const SizedBox(height: 12),
          Text('Belirsiz: ${preview.unknownCount} (korunur). '
              'Tim dışı: ${preview.outsideCount}.'),
          const SizedBox(height: 12),
          if (preview.candidates.isEmpty)
            const Text('Onarılabilecek kayıt yok.')
          else ...[
            Text(
                '${preview.candidates.length} kayıt için önerilen görev timi:'),
            const SizedBox(height: 8),
            SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: preview.candidates.length,
                  itemBuilder: (context, index) {
                    final row = preview.candidates[index];
                    return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            'Atama #${row.assignmentId} · Faaliyet #${row.activityId} '
                            '· Personel #${row.personnelId}'),
                        subtitle: Text('${row.date} → ${row.teamName} '
                            '(Tim ID: ${row.teamId ?? 'yok'})'));
                  },
                )),
            const SizedBox(height: 12),
            const Text(
                'Tam yedek hassas bilgiler içerir. Güvenli bir konuma kaydedin; '
                'ardından aynı dosyayı yeniden seçip doğrulayın. Uygula seçilene kadar onarım yapılmaz.'),
          ],
        ],
      );
}
