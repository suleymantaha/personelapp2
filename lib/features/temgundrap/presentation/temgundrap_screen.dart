import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

enum _TemgundrapSection { daily, archive }

class TemgundrapScreen extends StatefulWidget {
  const TemgundrapScreen({super.key});

  @override
  State<TemgundrapScreen> createState() => _TemgundrapScreenState();
}

class _TemgundrapScreenState extends State<TemgundrapScreen> {
  final _repository = TemgundrapRepository();
  late Future<List<TemgundrapDocument>> _documents;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  _TemgundrapSection _section = _TemgundrapSection.daily;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _documents = _repository.getAll();
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _documents;
    } catch (error) {
      if (mounted) AppNotifications.error(context.l10n.temgundrapFailedToLoad('$error'));
    }
  }

  Future<void> _openForm([TemgundrapDocument? document]) async {
    final changed = await AppNavigator.toTemgundrapForm(
      context,
      document: document,
      date: document?.date ?? _selectedDate,
    );
    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = DateUtils.dateOnly(picked));
    }
  }

  void _changeDay(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
  }

  Future<void> _setArchived(
    TemgundrapDocument document, {
    required bool archived,
  }) async {
    try {
      await _repository.save(
        document.copyWith(isDraft: !archived, updatedAt: DateTime.now()),
      );
      if (!mounted) return;
      setState(_reload);
      AppNotifications.info(
        archived
            ? context.l10n.temgundrapArchivedSuccess
            : context.l10n.temgundrapUnarchivedSuccess,
      );
    } catch (error) {
      if (mounted) AppNotifications.error(context.l10n.temgundrapUpdateFailed('$error'));
    }
  }

  Future<void> _delete(TemgundrapDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.temgundrapDeleteTitle),
            content: Text(
              dialogContext.l10n.temgundrapDeleteContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(dialogContext.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(dialogContext.l10n.commonDelete),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(document.id);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) AppNotifications.error(context.l10n.temgundrapDeleteFailed('$error'));
    }
  }

  Future<void> _showDocumentActions(TemgundrapDocument document) async {
    final action = await showModernActionSheet<String>(
      context,
      title: context.l10n.temgundrapActionsTitle,
      subtitle: _formatDate(document.date),
      icon: Icons.description_outlined,
      options: [
        ModernActionOption(
          value: 'edit',
          title: context.l10n.commonEdit,
          subtitle: context.l10n.temgundrapEditSubtitle,
          icon: Icons.edit_outlined,
        ),
        if (document.isDraft)
          ModernActionOption(
            value: 'archive',
            title: context.l10n.temgundrapArchiveOption,
            subtitle: context.l10n.temgundrapArchiveSubtitle,
            icon: Icons.archive_outlined,
          )
        else
          ModernActionOption(
            value: 'restore',
            title: context.l10n.temgundrapRestoreOption,
            subtitle: context.l10n.temgundrapRestoreSubtitle,
            icon: Icons.unarchive_outlined,
          ),
        ModernActionOption(
          value: 'delete',
          title: context.l10n.commonDelete,
          subtitle: context.l10n.temgundrapDeleteSubtitle,
          icon: Icons.delete_outline,
          isDestructive: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _openForm(document);
      case 'archive':
        await _setArchived(document, archived: true);
      case 'restore':
        await _setArchived(document, archived: false);
      case 'delete':
        await _delete(document);
    }
  }

  @override
  @override
  Widget build(BuildContext context) => FutureBuilder<List<TemgundrapDocument>>(
    future: _documents,
    builder: (context, snapshot) {
      final documents = snapshot.data ?? const [];
      final visible =
          documents.where((document) {
              final hasSameDate = DateUtils.isSameDay(
                document.date,
                _selectedDate,
              );
              final hasMatchingState =
                  _section == _TemgundrapSection.daily
                      ? document.isDraft
                      : !document.isDraft;
              return hasSameDate && hasMatchingState;
            }).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final draftCount = documents.where((document) => document.isDraft).length;
      final archiveCount = documents.length - draftCount;

      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(
            _section == _TemgundrapSection.daily
                ? context.l10n.temgundrapDailyTitle
                : context.l10n.temgundrapArchiveTitle,
          ),
          actions: [
            IconButton(
              key: const Key('temgundrap-date-picker'),
              tooltip: context.l10n.temgundrapPickDateTooltip,
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
        floatingActionButton:
            (_section == _TemgundrapSection.daily && visible.isNotEmpty)
                ? FloatingActionButton.extended(
                  key: const Key('new-temgundrap-document-fab'),
                  onPressed: _openForm,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.l10n.temgundrapNewDocument),
                )
                : null,
        body: TurkishFlagWatermarkBackground(
          child: () {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AppErrorState(
                title: context.l10n.temgundrapFailedToLoadDocs,
                error: '${snapshot.error}',
                onRetry: () => setState(_reload),
              );
            }

            return Column(
              children: [
                _SectionSwitcher(
                  section: _section,
                  draftCount: draftCount,
                  archiveCount: archiveCount,
                  onChanged: (section) => setState(() => _section = section),
                ),
                _DateNavigator(
                  date: _selectedDate,
                  onPrevious: () => _changeDay(-1),
                  onNext: () => _changeDay(1),
                  onPick: _pickDate,
                  onToday:
                      DateUtils.isSameDay(_selectedDate, DateTime.now())
                          ? null
                          : () => setState(
                            () =>
                                _selectedDate = DateUtils.dateOnly(
                                  DateTime.now(),
                                ),
                          ),
                ),
                Expanded(
                  child:
                      visible.isEmpty
                          ? _EmptySection(
                            section: _section,
                            date: _selectedDate,
                            onCreate: _openForm,
                            onPickDate: _pickDate,
                          )
                          : RefreshIndicator(
                            onRefresh: _refresh,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 700;
                                return GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    wide ? 24 : 12,
                                    8,
                                    wide ? 24 : 12,
                                    104,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 520,
                                        mainAxisExtent: wide ? 178 : 152,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                      ),
                                  itemCount: visible.length,
                                  itemBuilder:
                                      (context, index) => _DocumentCard(
                                        document: visible[index],
                                        onOpen:
                                            () => AppNavigator.toTemgundrapPreview(
                                              context,
                                              document: visible[index],
                                            ),
                                        onActions:
                                            () => _showDocumentActions(
                                              visible[index],
                                            ),
                                      ),
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          }(),
        ),
      );
    },
  );
}

class _SectionSwitcher extends StatelessWidget {
  const _SectionSwitcher({
    required this.section,
    required this.draftCount,
    required this.archiveCount,
    required this.onChanged,
  });

  final _TemgundrapSection section;
  final int draftCount;
  final int archiveCount;
  final ValueChanged<_TemgundrapSection> onChanged;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<_TemgundrapSection>(
            segments: [
              ButtonSegment(
                value: _TemgundrapSection.daily,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(
                  context.l10n.temgundrapDailyWithCount(draftCount),
                  key: const Key('temgundrap-daily-tab'),
                ),
              ),
              ButtonSegment(
                value: _TemgundrapSection.archive,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  context.l10n.temgundrapArchiveWithCount(archiveCount),
                  key: const Key('temgundrap-archive-tab'),
                ),
              ),
            ],
            selected: {section},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ),
    ),
  );
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    required this.onToday,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('temgundrap-previous-day'),
                tooltip: context.l10n.temgundrapPreviousDay,
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onPick,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDate(date),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (onToday != null)
                          TextButton(
                            key: const Key('temgundrap-today'),
                            onPressed: onToday,
                            child: Text(context.l10n.temgundrapBackToToday),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('temgundrap-next-day'),
                tooltip: context.l10n.temgundrapNextDay,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onOpen,
    required this.onActions,
  });

  final TemgundrapDocument document;
  final VoidCallback onOpen;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) => AppCard(
    key: Key('temgundrap-document-${document.id}'),
    onTap: onOpen,
    trailingAction: IconButton(
      key: Key('temgundrap-actions-${document.id}'),
      tooltip: context.l10n.temgundrapActionsTitle,
      onPressed: onActions,
      icon: const Icon(Icons.more_horiz_rounded),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.accentOrOlive.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                document.isDraft
                    ? Icons.edit_note_rounded
                    : Icons.inventory_2_outlined,
                color: context.accentOrOlive,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          document.unitTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 18,
              color: context.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.l10n.temgundrapOperationsCount(document.operations.length),
                style: TextStyle(color: context.textSecondary),
              ),
            ),
            _StatusBadge(isDraft: document.isDraft),
          ],
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isDraft});
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final color = isDraft ? context.warningColor : context.accentOrOlive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isDraft ? context.l10n.temgundrapBadgeDraft : context.l10n.temgundrapBadgeArchived,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.section,
    required this.date,
    required this.onCreate,
    required this.onPickDate,
  });

  final _TemgundrapSection section;
  final DateTime date;
  final VoidCallback onCreate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final isDaily = section == _TemgundrapSection.daily;
    return AppEmptyState(
      icon: isDaily ? Icons.edit_calendar_outlined : Icons.inventory_2_outlined,
      title: isDaily
          ? context.l10n.temgundrapNoDailyDraftTitle
          : context.l10n.temgundrapNoArchivedDocTitle,
      description: isDaily
          ? context.l10n.temgundrapNoDailyDraftMessage(_formatDate(date))
          : context.l10n.temgundrapNoArchivedDocMessage,
      action: FilledButton.icon(
        onPressed: isDaily ? onCreate : onPickDate,
        icon: Icon(isDaily ? Icons.add_rounded : Icons.calendar_month_outlined),
        label: Text(
          isDaily
              ? context.l10n.temgundrapNewDocButton
              : context.l10n.temgundrapPickDateButton,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
}
