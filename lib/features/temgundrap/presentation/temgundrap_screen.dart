import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
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
    await _documents;
  }

  Future<void> _openForm([TemgundrapDocument? document]) async {
    final date = _isoDate(document?.date ?? _selectedDate);
    final changed = await context.push<bool>(
      '/temgundrap/form?date=$date',
      extra: document,
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
    await _repository.save(
      document.copyWith(isDraft: !archived, updatedAt: DateTime.now()),
    );
    if (!mounted) return;
    setState(_reload);
    AppNotifications.info(
      archived
          ? 'Çizelge arşive taşındı.'
          : 'Çizelge yeniden taslağa alındı.',
    );
  }

  Future<void> _delete(TemgundrapDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çizelgeyi sil'),
        content: const Text(
          'Bu TEMGÜNDRAP çizelgesi kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.delete(document.id);
    if (mounted) setState(_reload);
  }

  Future<void> _showDocumentActions(TemgundrapDocument document) async {
    final action = await showModernActionSheet<String>(
      context,
      title: 'Çizelge İşlemleri',
      subtitle: _formatDate(document.date),
      icon: Icons.description_outlined,
      options: [
        const ModernActionOption(
          value: 'edit',
          title: 'Düzenle',
          subtitle: 'Çizelge bilgilerini güncelle',
          icon: Icons.edit_outlined,
        ),
        if (document.isDraft)
          const ModernActionOption(
            value: 'archive',
            title: 'Arşivle',
            subtitle: 'Çizelgeyi tamamla ve arşive taşı',
            icon: Icons.archive_outlined,
          )
        else
          const ModernActionOption(
            value: 'restore',
            title: 'Taslağa al',
            subtitle: 'Çizelgeyi yeniden düzenlemeye aç',
            icon: Icons.unarchive_outlined,
          ),
        const ModernActionOption(
          value: 'delete',
          title: 'Sil',
          subtitle: 'Bu çizelgeyi kalıcı olarak kaldır',
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
          final visible = documents.where((document) {
            final hasSameDate = DateUtils.isSameDay(
              document.date,
              _selectedDate,
            );
            final hasMatchingState = _section == _TemgundrapSection.daily
                ? document.isDraft
                : !document.isDraft;
            return hasSameDate && hasMatchingState;
          }).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          final draftCount =
              documents.where((document) => document.isDraft).length;
          final archiveCount = documents.length - draftCount;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                _section == _TemgundrapSection.daily
                    ? 'Günlük TEMGÜNDRAP'
                    : 'TEMGÜNDRAP Arşivi',
              ),
              actions: [
                IconButton(
                  key: const Key('temgundrap-date-picker'),
                  tooltip: 'Tarih seç',
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
                        label: const Text('Yeni Çizelge'),
                      )
                    : null,
            body: TurkishFlagWatermarkBackground(
              child: () {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Kayıtlar yüklenemedi',
                  message: '${snapshot.error}',
                  action: FilledButton.icon(
                    onPressed: () => setState(_reload),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('TEKRAR DENE'),
                  ),
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
                    onToday: DateUtils.isSameDay(_selectedDate, DateTime.now())
                        ? null
                        : () => setState(
                              () => _selectedDate =
                                  DateUtils.dateOnly(DateTime.now()),
                            ),
                  ),
                  Expanded(
                    child: visible.isEmpty
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
                                  itemBuilder: (context, index) =>
                                      _DocumentCard(
                                    document: visible[index],
                                    onOpen: () => context.push(
                                      '/temgundrap/preview',
                                      extra: visible[index],
                                    ),
                                    onActions: () => _showDocumentActions(
                                        visible[index]),
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
                      'Günlük Çizelge ($draftCount)',
                      key: const Key('temgundrap-daily-tab'),
                    ),
                  ),
                  ButtonSegment(
                    value: _TemgundrapSection.archive,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(
                      'Arşiv ($archiveCount)',
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
                    tooltip: 'Önceki gün',
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
                                child: const Text('BUGÜNE DÖN'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('temgundrap-next-day'),
                    tooltip: 'Sonraki gün',
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
  Widget build(BuildContext context) => Card(
        key: Key('temgundrap-document-${document.id}'),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    const Spacer(),
                    IconButton(
                      key: Key('temgundrap-actions-${document.id}'),
                      tooltip: 'Çizelge işlemleri',
                      onPressed: onActions,
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  document.unitTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
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
                        '${document.operations.length} operasyon',
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                    _StatusBadge(isDraft: document.isDraft),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isDraft});
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final color = isDraft ? Colors.orange.shade800 : context.accentOrOlive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isDraft ? 'TASLAK' : 'ARŞİVDE',
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
    return _MessageState(
      icon: isDaily ? Icons.edit_calendar_outlined : Icons.inventory_2_outlined,
      title: isDaily
          ? 'Bu güne ait taslak çizelge yok'
          : 'Bu tarihte arşivlenmiş çizelge yok',
      message: isDaily
          ? '${_formatDate(date)} için yeni bir TEMGÜNDRAP çizelgesi oluşturun.'
          : 'Başka bir tarih seçebilir veya tamamlanan bir taslağı arşivleyebilirsiniz.',
      action: FilledButton.icon(
        onPressed: isDaily ? onCreate : onPickDate,
        icon: Icon(isDaily ? Icons.add_rounded : Icons.calendar_month_outlined),
        label: Text(isDaily ? 'YENİ ÇİZELGE' : 'TARİH SEÇ'),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: context.accentOrOlive),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary),
                ),
                const SizedBox(height: 22),
                action,
              ],
            ),
          ),
        ),
      );
}

String _isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _formatDate(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}
