import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';

class ActivityBlockCard extends StatelessWidget {
  const ActivityBlockCard({
    required this.block,
    required this.blockIdx,
    required this.duplicates,
    required this.allSquads,
    required this.focusedPersonKey,
    required this.onEditBlock,
    required this.onRemoveBlock,
    required this.onSelectPersonnel,
    required this.onRemovePerson,
    this.cardKey,
    this.visiblePersonnelIndexes,
    super.key,
  });

  final ParsedActivityBlock block;
  final int blockIdx;
  final Map<String, List<String>> duplicates;
  final List<TimTableData> allSquads;
  final String? focusedPersonKey;
  final void Function(int blockIdx) onEditBlock;
  final void Function(int blockIdx) onRemoveBlock;
  final void Function(int blockIdx, int personIdx) onSelectPersonnel;
  final void Function(int blockIdx, int personIdx) onRemovePerson;
  final Key? cardKey;
  final List<int>? visiblePersonnelIndexes;

  @override
  Widget build(BuildContext context) {
    final personnelIndexes = visiblePersonnelIndexes ??
        List<int>.generate(block.personnelList.length, (index) => index);
    final problemCount =
        block.personnelList.isEmpty ? 1 : visiblePersonnelIndexes?.length ?? 0;

    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.cardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    block.parsedTimName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.accentOrOlive,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.parsedActivityType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _MetadataLabel(
                            icon: Icons.calendar_today_rounded,
                            text: block.parsedDate,
                          ),
                          if (block.parsedTimeRange?.trim().isNotEmpty == true)
                            _MetadataLabel(
                              icon: Icons.schedule_rounded,
                              text: block.parsedTimeRange!,
                            ),
                          _MetadataLabel(
                            icon: Icons.people_outline_rounded,
                            text: visiblePersonnelIndexes == null
                                ? '${block.personnelList.length} personel'
                                : '$problemCount sorun / '
                                    '${block.personnelList.length} personel',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  key: Key('bulk-card-menu-$blockIdx'),
                  tooltip: 'Kart işlemleri',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditBlock(blockIdx);
                    } else if (value == 'delete') {
                      onRemoveBlock(blockIdx);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Kartı düzenle'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.delete_outline, color: Colors.redAccent),
                        title: Text('Kartı sil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            if (block.personnelList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bu kartta personel kalmadı. Kartı silin veya metni yeniden ayrıştırın.',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: personnelIndexes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, visibleIndex) {
                  final pIdx = personnelIndexes[visibleIndex];
                  final item = block.personnelList[pIdx];
                  final duplicateWith = duplicates['$blockIdx:$pIdx'];
                  final personKey = '$blockIdx:$pIdx';
                  final isFocused = focusedPersonKey == personKey;
                  return PersonnelMatchCard(
                    key: Key('bulk-person-$blockIdx-$pIdx'),
                    item: item,
                    teamName: allSquads
                            .where((team) => team.id == item.matchedTimId)
                            .map((team) => team.timAdi)
                            .firstOrNull ??
                        'Tim bilgisi yok',
                    duplicateAssignments: duplicateWith,
                    isFocused: isFocused,
                    onSelect: () => onSelectPersonnel(blockIdx, pIdx),
                    onDelete: () => onRemovePerson(blockIdx, pIdx),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MetadataLabel extends StatelessWidget {
  const _MetadataLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
