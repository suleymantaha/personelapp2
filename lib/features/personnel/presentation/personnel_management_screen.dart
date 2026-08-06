import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/bulk_personnel_import_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_form_dialog.dart';

part 'personnel_management_actions.dart';
part 'squad_management_actions.dart';
part 'personnel_management_app_bar.dart';
part 'personnel_management_filters.dart';

class PersonnelManagementScreen extends ConsumerStatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  ConsumerState<PersonnelManagementScreen> createState() =>
      _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState
    extends ConsumerState<PersonnelManagementScreen> {
  int? _selectedFilterTimId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updatePersonnelView(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;

    final personnelAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);

    return Scaffold(
      appBar: _buildPersonnelAppBar(
        context: context,
        isAdmin: isAdmin,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddPersonnelDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Personel Ekle'),
            )
          : null,
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: AppSpacing.readableContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildPersonnelFilters(
                context: context,
                isAdmin: isAdmin,
                session: session,
                squadsAsync: squadsAsync,
              ),
              // 3. Personnel List Grouped by Squad (Matching Activity Form layout)
              personnelAsync.when(
                data: (rawPersonnelList) {
                  final squads = squadsAsync.value ?? [];
                  final squadMap = {for (final s in squads) s.id: s.timAdi};

                  // Filter by squad & commander permissions & search query
                  final personnelList = rawPersonnelList.where((p) {
                    // If Commander, restrict to commander's squad
                    if (!isAdmin) {
                      if (session?.timId == null) {
                        return false;
                      }

                      if (p.timId != session?.timId) {
                        return false;
                      }
                    }

                    // Squad filter chip selection
                    if (_selectedFilterTimId != null) {
                      if (_selectedFilterTimId == -1) {
                        if (p.timId != null) return false;
                      } else {
                        if (p.timId != _selectedFilterTimId) return false;
                      }
                    }

                    // Search query filter
                    if (_searchQuery.isNotEmpty) {
                      // Use fuzzy matching for better search results
                      final matches = PersonnelFuzzyMatcher.searchPersonnel(
                        _searchQuery,
                        [p],
                        threshold: 0.3, // Lower threshold for filtering
                        maxResults: 1,
                      );
                      if (matches.isEmpty) return false;
                    }

                    return true;
                  }).toList();

                  if (personnelList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Kriterlere uygun personel bulunamadı.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    );
                  }

                  // Group personnel by Squad (timId)
                  final grouped = <int?, List<PersonelTableData>>{};
                  for (final p in personnelList) {
                    grouped.putIfAbsent(p.timId, () => []).add(p);
                  }

                  final sortedTimIds = grouped.keys.toList()
                    ..sort((a, b) {
                      if (a == null) return 1;
                      if (b == null) return -1;
                      final nameA = squadMap[a] ?? '';
                      final nameB = squadMap[b] ?? '';
                      final wA = MilitaryStructureHelper.getSquadOrderWeight(
                        nameA,
                      );
                      final wB = MilitaryStructureHelper.getSquadOrderWeight(
                        nameB,
                      );
                      if (wA != wB) return wA.compareTo(wB);
                      return nameA.compareTo(nameB);
                    });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Personel Listesi (${personnelList.length} Kişi)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resmi Tim & Kıdem Sıralı',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...sortedTimIds.map((timId) {
                        final members = grouped[timId]!
                          ..sort(
                            (a, b) => getRankWeight(
                              a.rutbe,
                            ).compareTo(getRankWeight(b.rutbe)),
                          );

                        final squadName = timId == null
                            ? 'Boşta / Kadro Dışı Personeller'
                            : (squadMap[timId] ?? 'Bilinmeyen Tim');

                        return ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          childrenPadding: const EdgeInsets.only(bottom: 14),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  squadName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: context.accentOrOlive,
                                  ),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 112,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.accentOrOlive,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${members.length} personel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.onAccentOrOlive,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              separatorBuilder: (context, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = members[index];

                                return Card(
                                  elevation: 0,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: context.cardBorderColor,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: context.accentOrOlive,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: context.onAccentOrOlive,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${p.rutbe} ${p.adSoyad}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Birlik: ${p.birlik} | Kayıt: ${p.kayitTarihi}',
                                      ),
                                    ),
                                    trailing: isAdmin
                                        ? PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            tooltip: 'İşlemler',
                                            elevation: 5,
                                            shadowColor: context.shadowColor,
                                            surfaceTintColor:
                                                context.colorScheme.surface,
                                            shape: modernPopupShape(context),
                                            constraints: const BoxConstraints(
                                              minWidth: 300,
                                              maxWidth: 340,
                                            ),
                                            onSelected: (action) async {
                                              if (action == 'edit') {
                                                await _showEditPersonnelDialog(
                                                  p,
                                                );
                                              } else if (action ==
                                                  'commander') {
                                                await _showMakeCommanderDialog(
                                                  p,
                                                );
                                              } else if (action == 'delete') {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Personeli Sil',
                                                    ),
                                                    content: Text(
                                                      '${p.rutbe} ${p.adSoyad} isimli personel sistemden silinecektir. Emin misiniz?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                        child: const Text(
                                                          'İPTAL',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              context
                                                                  .rejectedColor,
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                        child: const Text(
                                                          'SİL',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  final repo = ref.read(
                                                    personnelRepositoryProvider,
                                                  );
                                                  await repo.deletePersonnel(
                                                    p.id,
                                                  );
                                                }
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              ModernMenuHeader<String>(
                                                title: 'Personel İşlemleri',
                                                subtitle:
                                                    '${p.rutbe} ${p.adSoyad}',
                                                icon: Icons.person_outline,
                                              ),
                                              const PopupMenuDivider(),
                                              ModernPopupMenuItem(
                                                option:
                                                    const ModernActionOption(
                                                  value: 'edit',
                                                  title:
                                                      'Düzenle / Tim değiştir',
                                                  subtitle:
                                                      'Personel bilgilerini güncelle',
                                                  icon: Icons.edit_outlined,
                                                ),
                                              ),
                                              ModernPopupMenuItem(
                                                option:
                                                    const ModernActionOption(
                                                  value: 'commander',
                                                  title: 'Komutan yetkileri',
                                                  subtitle:
                                                      'Tim komutanı yap veya yetki ver',
                                                  icon: Icons.star_outline,
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              ModernPopupMenuItem(
                                                option:
                                                    const ModernActionOption(
                                                  value: 'delete',
                                                  title: 'Personeli sil',
                                                  subtitle:
                                                      'Bu işlem geri alınamaz',
                                                  icon: Icons
                                                      .delete_outline_rounded,
                                                  isDestructive: true,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Hata: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
