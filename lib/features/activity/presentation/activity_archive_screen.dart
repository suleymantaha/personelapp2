import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

final allActivitiesProvider = StreamProvider<List<GunlukFaaliyetTableData>>((ref) {
  return ref.watch(activityRepositoryProvider).watchAllActivities();
});

class ActivityArchiveScreen extends ConsumerStatefulWidget {
  const ActivityArchiveScreen({super.key});

  @override
  ConsumerState<ActivityArchiveScreen> createState() => _ActivityArchiveScreenState();
}

class _ActivityArchiveScreenState extends ConsumerState<ActivityArchiveScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(allActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faaliyet Arşivi'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Faaliyet Ara (Tarih veya Ad)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),

          // Activity List
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                final filtered = activities.where((act) {
                  final nameMatch = act.faaliyetAdi.toLowerCase().contains(_searchQuery);
                  final dateMatch = act.tarih.toLowerCase().contains(_searchQuery);
                  return nameMatch || dateMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Kayıtlı faaliyet bulunamadı.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final act = filtered[index];
                    return _ActivityCard(activity: act);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Hata: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  final GunlukFaaliyetTableData activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightOlive),
      ),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.militaryOlive,
          child: Icon(Icons.article, color: Colors.white),
        ),
        title: Text(
          activity.faaliyetAdi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Tarih: ${activity.tarih} | Oluşturan: ${activity.olusturanKullanici}'),
        trailing: isAdmin
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.rejectedRed),
                tooltip: 'Faaliyeti Sil',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Faaliyeti Sil'),
                      content: Text(
                        '${activity.faaliyetAdi} (${activity.tarih}) faaliyet kaydı silinecektir. Emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('İPTAL'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rejectedRed,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('SİL'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final db = ref.read(databaseProvider);
                    await (db.delete(db.gunlukFaaliyetTable)
                          ..where((tbl) => tbl.id.equals(activity.id)))
                        .go();
                  }
                },
              )
            : null,
        children: [
          _AssignmentDetails(activityId: activity.id, dateStr: activity.tarih),
        ],
      ),
    );
  }
}

class _AssignmentDetails extends ConsumerWidget {
  final int activityId;
  final String dateStr;

  const _AssignmentDetails({required this.activityId, required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
      stream: (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.faaliyetId.equals(activityId)))
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Görevlendirilmiş personel kaydı bulunmuyor.'),
          );
        }

        return Container(
          color: const Color(0xFFF9FAF7),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: assignments.map((atama) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Personel ID: ${atama.personelId}'),
                    Chip(
                      label: Text(
                        '${atama.gorevVeyaIzin} (${atama.durum})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: atama.durum == 'onaylandi'
                          ? AppColors.approvedGreen.withValues(alpha: 0.15)
                          : AppColors.pendingYellow.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
