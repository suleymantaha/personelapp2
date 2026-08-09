import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/widgets/collapsible_squad_card.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

class ActivityAssignmentPreviewScreen extends StatefulWidget {
  const ActivityAssignmentPreviewScreen({
    required this.activityName,
    required this.date,
    required this.preview,
    required this.requiresAdminApproval,
    required this.onConfirm,
    super.key,
  });

  final String activityName;
  final DateTime date;
  final ActivityAssignmentPreview preview;
  final bool requiresAdminApproval;
  final Future<bool> Function() onConfirm;

  @override
  State<ActivityAssignmentPreviewScreen> createState() =>
      _ActivityAssignmentPreviewScreenState();
}

class _ActivityAssignmentPreviewScreenState
    extends State<ActivityAssignmentPreviewScreen> {
  int? _expandedSquadId;
  bool _timDisiExpanded = false;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.onConfirm();
      if (saved && mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görevlendirme kaydedilemedi: $error'),
          backgroundColor: context.rejectedColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int?, List<ActivityAssignmentPreviewItem>>{};
    for (final item in widget.preview.items) {
      grouped.putIfAbsent(item.squadId, () => []).add(item);
    }
    for (final items in grouped.values) {
      items.sort((a, b) {
        final rank = getRankWeight(a.rank).compareTo(getRankWeight(b.rank));
        return rank != 0 ? rank : a.name.compareTo(b.name);
      });
    }
    final squadIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = widget.preview.squadNames[a] ?? '';
        final nameB = widget.preview.squadNames[b] ?? '';
        final weight = MilitaryStructureHelper.getSquadOrderWeight(nameA)
            .compareTo(MilitaryStructureHelper.getSquadOrderWeight(nameB));
        return weight != 0 ? weight : nameA.compareTo(nameB);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevlendirme Önizlemesi'),
        leading: IconButton(
          key: const Key('preview-back-button'),
          tooltip: 'Geri dön ve düzelt',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 12,
        color: context.colorScheme.surface,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('preview-edit-button'),
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Geri Dön ve Düzelt'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('preview-confirm-button'),
                  onPressed: _saving ? null : _confirm,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Kaydediliyor…' : 'Onayla ve Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TurkishFlagWatermarkBackground(
        child: ResponsiveCenter(
        maxWidth: AppSpacing.readableContentWidth,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: ListView(
          children: [
            _PreviewHeader(
              activityName: widget.activityName,
              date: widget.date,
              personnelCount: widget.preview.items.length,
              squadCount: widget.preview.squadCount,
              warningCount: widget.preview.warningCount,
            ),
            const SizedBox(height: 16),
            if (widget.preview.warningCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.pendingColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.pendingColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  '${widget.preview.warningCount} personel mevcut görev, izin '
                  'veya rapor çakışması nedeniyle kaydedilmeyecek.',
                  style: TextStyle(
                    color: context.pendingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ...squadIds.map((squadId) {
              final items = grouped[squadId]!;
              final teamName = squadId == null
                  ? 'Tim Dışı'
                  : (widget.preview.squadNames[squadId] ?? 'Bilinmeyen Tim');
              final summary = _dutySummary(items);
              final warnings = items.where((item) => item.hasConflict).length;
              final expanded = squadId == null
                  ? _timDisiExpanded
                  : _expandedSquadId == squadId;
              return CollapsibleSquadCard(
                cardKey: Key('preview-team-card-$squadId'),
                headerKey: Key('preview-team-header-$squadId'),
                title: '$teamName • ${items.length} kişi • $summary',
                expanded: expanded,
                warningCount: warnings,
                onToggle: () => setState(() {
                  if (squadId == null) {
                    _timDisiExpanded = !_timDisiExpanded;
                    _expandedSquadId = null;
                  } else {
                    _expandedSquadId = expanded ? null : squadId;
                    _timDisiExpanded = false;
                  }
                }),
                children: items
                    .map(
                      (item) => _PreviewPersonnelRow(
                        item: item,
                        requiresAdminApproval: widget.requiresAdminApproval,
                      ),
                    )
                    .toList(growable: false),
              );
            }),
          ],
        ),
      ),
    ),
    );
  }

  String _dutySummary(List<ActivityAssignmentPreviewItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts.update(item.duty, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts.entries
        .map((entry) => '${entry.value} ${entry.key}')
        .join(', ');
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.activityName,
    required this.date,
    required this.personnelCount,
    required this.squadCount,
    required this.warningCount,
  });

  final String activityName;
  final DateTime date;
  final int personnelCount;
  final int squadCount;
  final int warningCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activityName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy').format(date),
              style: context.textStyleSecondary,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                    icon: Icons.people_outline,
                    label: '$personnelCount personel'),
                _StatChip(
                    icon: Icons.shield_outlined, label: '$squadCount tim'),
                _StatChip(
                  icon: warningCount > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  label: '$warningCount uyarı',
                  color: warningCount > 0
                      ? context.pendingColor
                      : context.approvedColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.accentOrOlive;
    return Chip(
      avatar: Icon(icon, size: 17, color: effectiveColor),
      label: Text(label),
      side: BorderSide(color: effectiveColor.withValues(alpha: 0.4)),
    );
  }
}

class _PreviewPersonnelRow extends StatelessWidget {
  const _PreviewPersonnelRow({
    required this.item,
    required this.requiresAdminApproval,
  });

  final ActivityAssignmentPreviewItem item;
  final bool requiresAdminApproval;

  @override
  Widget build(BuildContext context) {
    final label = item.hasConflict
        ? 'Kaydedilmeyecek'
        : requiresAdminApproval
            ? 'Admin onayı bekleyecek'
            : 'Kaydedilecek';
    final color = item.hasConflict
        ? context.rejectedColor
        : requiresAdminApproval
            ? context.pendingColor
            : context.approvedColor;
    return ListTile(
      key: Key('preview-person-${item.personnelId}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text('${item.rank} ${item.name}'.trim()),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.duty, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (item.note?.trim().isNotEmpty ?? false) Text(item.note!.trim()),
        ],
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 130),
        child: Text(
          label,
          textAlign: TextAlign.end,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
