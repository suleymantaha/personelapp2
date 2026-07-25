import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAssignmentsProvider);
    final personnelAsync = ref.watch(allPersonnelProvider);

    final personnelList = personnelAsync.value ?? [];
    final pMap = {for (final p in personnelList) p.id: p};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleyen Görev Onayları'),
      ),
      body: pendingAsync.when(
        data: (pendingList) {
          if (pendingList.isEmpty) {
            return Center(
              child: Text(
                'Onay bekleyen veya çakışan görev kaydı bulunmuyor.',
                style: TextStyle(fontSize: 16, color: context.textSecondary),
              ),
            );
          }

          return ResponsiveCenter(
            maxWidth: 900,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final atama = pendingList[index];
                final p = pMap[atama.personelId];
                final nameText = p?.adSoyad ?? 'Personel #${atama.personelId}';
                final rutbeText = p?.rutbe ?? '';
                final birlikInfo = p?.birlik ?? '';
                final fullPersonName = rutbeText.isNotEmpty
                    ? '$rutbeText $nameText'
                    : nameText;
                final squadInfo = birlikInfo.isNotEmpty ? ' ($birlikInfo)' : '';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: context.pendingColor, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: context.pendingColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Görevlendirme #${atama.id} (ÇAKIŞMA VAR)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Personel: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '$fullPersonName$squadInfo',
                                style: TextStyle(
                                  color: context.accentOrOlive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Talep Edilen Görev: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: atama.gorevVeyaIzin,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (atama.aciklama != null &&
                            atama.aciklama!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Açıklama: ${atama.aciklama}',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.rejectedColor,
                              ),
                              onPressed: () async {
                                final repo = ref.read(
                                  activityRepositoryProvider,
                                );
                                await repo.updateAssignmentStatus(
                                  atama.id,
                                  AssignmentStatus.reddedildi,
                                );
                              },
                              child: const Text('REDDET'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.approvedColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final repo = ref.read(
                                  activityRepositoryProvider,
                                );
                                await repo.updateAssignmentStatus(
                                  atama.id,
                                  AssignmentStatus.onaylandi,
                                );
                              },
                              child: const Text('ONAYLA'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
