import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_metadata_label.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';

class ActivityBlockCard extends StatefulWidget {
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
    this.onConfirmPersonnelSuggestion,
    this.onAddNewPersonnel,
    this.cardKey,
    this.personKeys,
    this.visiblePersonnelIndexes,
    this.isExpanded,
    this.onToggleExpand,
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
  final void Function(int blockIdx, int personIdx)?
      onConfirmPersonnelSuggestion;
  final void Function(int blockIdx, int personIdx)? onAddNewPersonnel;
  final Key? cardKey;
  final Map<String, GlobalKey>? personKeys;
  final List<int>? visiblePersonnelIndexes;
  final bool? isExpanded;
  final VoidCallback? onToggleExpand;

  @override
  State<ActivityBlockCard> createState() => _ActivityBlockCardState();
}

class _ActivityBlockCardState extends State<ActivityBlockCard> {
  bool? _userManualExpanded;

  bool get _hasBlockProblems {
    if (widget.block.personnelList.isEmpty) return true;
    if (widget.block.parsedDate.trim().isEmpty) return true;
    if (widget.block.parsedActivityType.trim().isEmpty) return true;
    for (var i = 0; i < widget.block.personnelList.length; i++) {
      final p = widget.block.personnelList[i];
      final isDup = widget.duplicates.containsKey('${widget.blockIdx}:$i');
      if (!p.isMatched || p.hasWarning || isDup) return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant ActivityBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedPersonKey != oldWidget.focusedPersonKey) {
      _userManualExpanded = null;
    }
    if (widget.isExpanded != oldWidget.isExpanded &&
        widget.isExpanded != null) {
      _userManualExpanded = widget.isExpanded;
    }
  }

  void _toggleExpand() {
    if (widget.onToggleExpand != null) {
      widget.onToggleExpand!();
    } else {
      setState(() {
        _userManualExpanded = !_effectiveIsExpanded;
      });
    }
  }

  bool get _effectiveIsExpanded {
    if (_userManualExpanded != null) {
      return _userManualExpanded!;
    }
    if (widget.focusedPersonKey != null) {
      return widget.focusedPersonKey!.startsWith('${widget.blockIdx}:');
    }
    if (widget.isExpanded != null) {
      return widget.isExpanded!;
    }
    return _hasBlockProblems;
  }

  @override
  Widget build(BuildContext context) {
    final isBlockFocused = widget.focusedPersonKey != null &&
        widget.focusedPersonKey!.startsWith('${widget.blockIdx}:');
    final effectiveIsExpanded = _effectiveIsExpanded;

    final personnelIndexes = widget.visiblePersonnelIndexes ??
        List<int>.generate(widget.block.personnelList.length, (index) => index);
    final problemCount = widget.block.personnelList.isEmpty
        ? 1
        : widget.visiblePersonnelIndexes?.length ?? 0;

    int unmatchedCount = 0;
    int warningCount = 0;
    for (var i = 0; i < widget.block.personnelList.length; i++) {
      final p = widget.block.personnelList[i];
      final isDup = widget.duplicates.containsKey('${widget.blockIdx}:$i');
      if (!p.isMatched) {
        unmatchedCount++;
      } else if (p.hasWarning || isDup) {
        warningCount++;
      }
    }

    final hasProblems = unmatchedCount > 0 ||
        warningCount > 0 ||
        widget.block.personnelList.isEmpty;
    final borderColor = isBlockFocused
        ? (unmatchedCount > 0 ? Colors.red.shade700 : Colors.amber.shade800)
        : (hasProblems
            ? (unmatchedCount > 0
                ? Colors.red.shade300
                : Colors.orange.shade300)
            : context.cardBorderColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isBlockFocused ? 2.5 : (hasProblems ? 1.2 : 1.0),
        ),
        boxShadow: isBlockFocused
            ? [
                BoxShadow(
                  color: (unmatchedCount > 0 ? Colors.red : Colors.amber)
                      .withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Material(
        key: widget.cardKey,
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Clickable InkWell to Collapse/Expand)
            InkWell(
              key: Key('bulk-card-header-${widget.blockIdx}'),
              onTap: _toggleExpand,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: Radius.circular(effectiveIsExpanded ? 0 : 12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.block.parsedTimName.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.accentOrOlive
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.block.parsedTimName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: context.accentOrOlive,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Varsayılan Tim',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  widget.block.parsedActivityType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.fade,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ActivityMetadataLabel(
                                icon: Icons.calendar_today_rounded,
                                text: widget.block.parsedDate,
                              ),
                              if (widget.block.parsedTimeRange
                                      ?.trim()
                                      .isNotEmpty ==
                                  true)
                                ActivityMetadataLabel(
                                  icon: Icons.schedule_rounded,
                                  text: widget.block.parsedTimeRange!,
                                ),
                              if (isBlockFocused)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (unmatchedCount > 0 ||
                                            widget.block.personnelList.isEmpty)
                                        ? Colors.red.shade800
                                        : Colors.amber.shade900,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (unmatchedCount > 0 ||
                                                widget.block.personnelList
                                                    .isEmpty)
                                            ? Icons.push_pin_rounded
                                            : Icons.search_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (unmatchedCount > 0 ||
                                                widget.block.personnelList
                                                    .isEmpty)
                                            ? 'ODAKLANILAN HATA'
                                            : 'İNCELENEN KART',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.block.personnelList.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Boş Kart',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (unmatchedCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$unmatchedCount Eşleşmedi',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (warningCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$warningCount Uyarı',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: context.approvedColor,
                                  size: 18,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ekran görüntünüzdeki koyu haki oval pill rozeti (Personel sayısı)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentOrOlive,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.visiblePersonnelIndexes == null
                            ? '${widget.block.personnelList.length} personel'
                            : '$problemCount sorun / ${widget.block.personnelList.length} p.',
                        style: TextStyle(
                          color: context.customColors.onAccentOrOlive,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Genişletme / Daraltma Oku (Expand Chevron)
                    Icon(
                      effectiveIsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: context.textSecondary,
                      size: 22,
                    ),

                    PopupMenuButton<String>(
                      key: Key('bulk-card-menu-${widget.blockIdx}'),
                      tooltip: 'Kart işlemleri',
                      elevation: 5,
                      shadowColor: context.shadowColor,
                      surfaceTintColor: context.colorScheme.surface,
                      shape: modernPopupShape(context),
                      constraints:
                          const BoxConstraints(minWidth: 280, maxWidth: 320),
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEditBlock(widget.blockIdx);
                        } else if (value == 'delete') {
                          widget.onRemoveBlock(widget.blockIdx);
                        }
                      },
                      itemBuilder: (context) => [
                        const ModernMenuHeader<String>(
                          title: 'Kart İşlemleri',
                          subtitle: 'İçe aktarma kartını yönet',
                          icon: Icons.view_agenda_outlined,
                        ),
                        const PopupMenuDivider(),
                        ModernPopupMenuItem(
                          option: const ModernActionOption(
                            value: 'edit',
                            title: 'Kartı düzenle',
                            subtitle:
                                'Faaliyet ve personel bilgilerini güncelle',
                            icon: Icons.edit_outlined,
                          ),
                        ),
                        const PopupMenuDivider(),
                        ModernPopupMenuItem(
                          option: const ModernActionOption(
                            value: 'delete',
                            title: 'Kartı sil',
                            subtitle: 'Kartı içe aktarma listesinden kaldır',
                            icon: Icons.delete_outline_rounded,
                            isDestructive: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Body (Only rendered if expanded)
            if (effectiveIsExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: widget.block.personnelList.isEmpty
                    ? Container(
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
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: personnelIndexes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, visibleIndex) {
                          final pIdx = personnelIndexes[visibleIndex];
                          final item = widget.block.personnelList[pIdx];
                          final duplicateWith =
                              widget.duplicates['${widget.blockIdx}:$pIdx'];
                          final personKey = '${widget.blockIdx}:$pIdx';
                          final isFocused =
                              widget.focusedPersonKey == personKey;
                          final registeredTeamName = widget.allSquads
                              .where((team) => team.id == item.matchedTimId)
                              .map((team) => team.timAdi)
                              .firstOrNull;
                          final listTeamName =
                              widget.block.parsedTimName.trim().isNotEmpty
                                  ? widget.block.parsedTimName
                                  : registeredTeamName ?? '';
                          final itemKey = widget.personKeys?.putIfAbsent(
                                personKey,
                                () => GlobalKey(),
                              ) ??
                              Key('bulk-person-${widget.blockIdx}-$pIdx');
                          return PersonnelMatchCard(
                            key: itemKey,
                            item: item,
                            teamName: listTeamName,
                            registeredTeamName: registeredTeamName,
                            duplicateAssignments: duplicateWith,
                            isFocused: isFocused,
                            onSelect: () =>
                                widget.onSelectPersonnel(widget.blockIdx, pIdx),
                            onDelete: () =>
                                widget.onRemovePerson(widget.blockIdx, pIdx),
                            onConfirmSuggestion:
                                widget.onConfirmPersonnelSuggestion != null
                                    ? () =>
                                        widget.onConfirmPersonnelSuggestion!(
                                            widget.blockIdx, pIdx)
                                    : null,
                            onAddNewPerson: widget.onAddNewPersonnel != null
                                ? () => widget.onAddNewPersonnel!(
                                    widget.blockIdx, pIdx)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
