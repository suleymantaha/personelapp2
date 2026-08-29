import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_date_navigator.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/services/activity_order_preferences.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

part 'activity_archive_actions.dart';

class ActivityArchiveScreen extends ConsumerStatefulWidget {
  const ActivityArchiveScreen({super.key});

  @override
  ConsumerState<ActivityArchiveScreen> createState() =>
      _ActivityArchiveScreenState();
}

class _ActivityArchiveScreenState extends ConsumerState<ActivityArchiveScreen> {
  DateTime _selectedDateFilter = DateTime.now();
  int? _selectedSquadFilter; // null = Tümü
  final Set<int> _selectedActivityIds = {};
  bool _selectionMode = false;
  bool _reorderMode = false;

  static const ActivityOrderPreferences _orderPreferences =
      ActivityOrderPreferences();
  String? _loadedOrderDate;
  List<int> _manualOrder = const [];

  void _updateState(VoidCallback callback) => setState(callback);

  @override
  void initState() {
    super.initState();
    _loadManualOrder(DateFormat('yyyy-MM-dd').format(_selectedDateFilter));
  }

  void _changeSelectedDate(DateTime date) {
    setState(() {
      _selectedDateFilter = date;
      _reorderMode = false;
    });
    _loadManualOrder(DateFormat('yyyy-MM-dd').format(date));
  }

  Future<void> _loadManualOrder(String date) async {
    List<int> order;
    try {
      order = await _orderPreferences.loadOrder(date);
    } on Object {
      // Saved order is a convenience; fall back to the default sorting when
      // local storage is unavailable.
      order = const [];
    }
    if (!mounted) return;
    setState(() {
      _loadedOrderDate = date;
      _manualOrder = order;
    });
  }

  /// Sorts activities using the manual order saved for [date].
  ///
  /// Cards the user has never moved keep their default position at the top,
  /// so newly added activities stay visible instead of dropping to the end.
  List<GunlukFaaliyetTableData> _applyManualOrder(
    List<GunlukFaaliyetTableData> activities,
    String date,
  ) {
    if (_loadedOrderDate != date || _manualOrder.isEmpty) return activities;
    final positions = <int, int>{
      for (var i = 0; i < _manualOrder.length; i++) _manualOrder[i]: i,
    };
    final ordered = List<GunlukFaaliyetTableData>.from(activities);
    for (var i = 0; i < ordered.length; i++) {
      positions.putIfAbsent(ordered[i].id, () => -ordered.length + i);
    }
    ordered.sort((a, b) => positions[a.id]!.compareTo(positions[b.id]!));
    return ordered;
  }

  Future<void> _handleReorder(
    List<GunlukFaaliyetTableData> activities,
    String date,
    int oldIndex,
    int newIndex,
  ) async {
    // [newIndex] already accounts for the removed item, so it is used as is.
    final reordered = List<GunlukFaaliyetTableData>.from(activities);
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    final ids = reordered.map((activity) => activity.id).toList();
    setState(() {
      _loadedOrderDate = date;
      _manualOrder = ids;
    });
    try {
      await _orderPreferences.saveOrder(date, ids);
    } on Object {
      AppNotifications.warning('Sıralama kaydedilemedi.');
    }
  }

  Future<void> _resetManualOrder(String date) async {
    try {
      await _orderPreferences.clearOrder(date);
    } on Object {
      AppNotifications.warning('Sıralama sıfırlanamadı.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadedOrderDate = date;
      _manualOrder = const [];
    });
    AppNotifications.info('Kart sıralaması varsayılana döndürüldü.');
  }

  Widget _buildActivityCard(GunlukFaaliyetTableData act) {
    return ActivityCard(
      key: ValueKey<int>(act.id),
      activity: act,
      selectedSquadId: _selectedSquadFilter,
      selectionMode: _selectionMode,
      isSelected: _selectedActivityIds.contains(act.id),
      onLongPress: _reorderMode ? null : () => _startSelection(act.id),
      onSelectionToggle: _reorderMode ? null : () => _toggleSelection(act.id),
      onDateChanged: (newDate) {
        final parsed = DateTime.tryParse(newDate);
        if (parsed != null) {
          _changeSelectedDate(parsed);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;

    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final personnelAsync = ref.watch(allPersonnelProvider);
    final squads = squadsAsync.value ?? [];
    final allPersonnel = personnelAsync.value ?? [];
    final personnelList = (!isAdmin && session?.timId != null)
        ? allPersonnel.where((p) => p.timId == session!.timId).toList()
        : (!isAdmin ? <PersonelTableData>[] : allPersonnel);

    final dateFilterStr = DateFormat('yyyy-MM-dd').format(_selectedDateFilter);
    final now = DateTime.now();
    final isSelectedToday = _selectedDateFilter.year == now.year &&
        _selectedDateFilter.month == now.month &&
        _selectedDateFilter.day == now.day;

    Future<void> pickArchiveDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDateFilter,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (!mounted || picked == null) return;
      _changeSelectedDate(picked);
    }

    void exportCurrentArchive() {
      final filteredForDate = (activitiesAsync.value ?? [])
          .where((activity) => activity.tarih == dateFilterStr)
          .toList();
      final hasSelectedSquad = _selectedSquadFilter != null &&
          squads.any((squad) => squad.id == _selectedSquadFilter);
      final selectedSquadName = hasSelectedSquad
          ? squads
              .firstWhere((squad) => squad.id == _selectedSquadFilter)
              .timAdi
          : null;
      final squadText =
          selectedSquadName == null ? '' : ' • $selectedSquadName';
      final subtitle =
          '${DateFormat('dd.MM.yyyy').format(_selectedDateFilter)} • '
          '${filteredForDate.length} Faaliyet$squadText';
      _exportWithSheet(filteredForDate, personnelList, subtitle: subtitle);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.accentOrOlive,
        foregroundColor: context.onAccentOrOlive,
        elevation: 0,
        centerTitle: false,
        titleSpacing: _selectionMode ? null : 0,
        leading: _selectionMode
            ? IconButton(
                key: const Key('activity-selection-close'),
                icon: const Icon(Icons.close),
                tooltip: 'Seçimi Kapat',
                onPressed: _clearSelection,
              )
            : null,
        title: Text(
          _selectionMode
              ? '${_selectedActivityIds.length} faaliyet seçildi'
              : (isAdmin ? 'Faaliyet Arşivi' : 'Tim Faaliyet Arşivi'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              key: const Key('activity-selection-export'),
              icon: const Icon(Icons.ios_share),
              tooltip: 'Seçilenleri Dışa Aktar',
              onPressed: () => _showSelectedExportOptions(
                activitiesAsync.value ?? [],
                personnelList,
              ),
            )
          else if (!context.isMobile)
            TextButton.icon(
              key: const Key('activity-selection-start'),
              onPressed: () => setState(() => _selectionMode = true),
              icon: const Icon(Icons.checklist),
              label: const Text('Seç'),
            ),
          if (!_selectionMode && context.isMobile)
            PopupMenuButton<String>(
              tooltip: 'Arşiv işlemleri',
              icon: const Icon(Icons.more_vert_rounded),
              elevation: 5,
              shadowColor: context.shadowColor,
              surfaceTintColor: context.colorScheme.surface,
              shape: modernPopupShape(context),
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
              onSelected: (action) async {
                switch (action) {
                  case 'export':
                    exportCurrentArchive();
                  case 'select':
                    setState(() => _selectionMode = true);
                  case 'today':
                    _changeSelectedDate(DateTime.now());
                  case 'reorder':
                    setState(() {
                      _reorderMode = !_reorderMode;
                      if (_reorderMode) {
                        _selectionMode = false;
                        _selectedActivityIds.clear();
                      }
                    });
                  case 'reset-order':
                    await _resetManualOrder(dateFilterStr);
                  case 'audit':
                    await _showConflictAudit();
                  case 'date':
                    await pickArchiveDate();
                }
              },
              itemBuilder: (context) => [
                const ModernMenuHeader<String>(
                  title: 'Arşiv İşlemleri',
                  subtitle: 'Görünüm ve arşiv araçları',
                  icon: Icons.inventory_2_outlined,
                ),
                const PopupMenuDivider(),
                ModernPopupMenuItem(
                  option: const ModernActionOption(
                    value: 'export',
                    title: 'Dışa Aktar / Yazdır',
                    subtitle: 'Görüntülenen günü paylaş veya yazdır',
                    icon: Icons.ios_share_rounded,
                  ),
                ),
                ModernPopupMenuItem(
                  option: const ModernActionOption(
                    value: 'select',
                    title: 'Faaliyet seç',
                    subtitle: 'Birden fazla kayıt üzerinde çalış',
                    icon: Icons.checklist_rounded,
                  ),
                ),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'reorder',
                    title: _reorderMode ? 'Sıralamayı bitir' : 'Kartları taşı',
                    subtitle: _reorderMode
                        ? 'Sürükleme modundan çık'
                        : 'Kartları sürükleyerek yeniden sırala',
                    icon: _reorderMode
                        ? Icons.check_rounded
                        : Icons.swap_vert_rounded,
                  ),
                ),
                if (_manualOrder.isNotEmpty)
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'reset-order',
                      title: 'Sıralamayı sıfırla',
                      subtitle: 'Varsayılan sıralamaya dön',
                      icon: Icons.restart_alt_rounded,
                    ),
                  ),
                if (!isSelectedToday)
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'today',
                      title: 'Bugüne dön',
                      subtitle: 'Güncel faaliyetleri göster',
                      icon: Icons.today_rounded,
                    ),
                  ),
                if (isAdmin)
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'audit',
                      title: 'Çakışmaları denetle',
                      subtitle: 'Personel görevlendirmelerini kontrol et',
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                ModernPopupMenuItem(
                  option: const ModernActionOption(
                    value: 'date',
                    title: 'Tarihe göre süz',
                    subtitle: 'Belirli bir günün arşivini aç',
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              key: const Key('activity-archive-export'),
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Dışa Aktar / Yazdır',
              onPressed: exportCurrentArchive,
            ),
          if (!_selectionMode && !context.isMobile && !isSelectedToday)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Bugüne Dön',
              onPressed: () => _changeSelectedDate(DateTime.now()),
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              key: const Key('activity-reorder-toggle'),
              icon: Icon(
                _reorderMode ? Icons.check_rounded : Icons.swap_vert_rounded,
              ),
              tooltip: _reorderMode ? 'Sıralamayı Bitir' : 'Kartları Taşı',
              onPressed: () => setState(() => _reorderMode = !_reorderMode),
            ),
          if (!_selectionMode && !context.isMobile && isAdmin)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Geçmiş Çakışmaları Denetle',
              onPressed: _showConflictAudit,
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Tarihe Göre Süz',
              onPressed: pickArchiveDate,
            ),
        ],
      ),
      body: TurkishFlagWatermarkBackground(
        child: ResponsiveCenter(
          maxWidth: AppSpacing.readableContentWidth,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              activitiesAsync.when(
                data: (activities) => ArchiveDateNavigator(
                  selectedDate: _selectedDateFilter,
                  activityCount: activities
                      .where((activity) => activity.tarih == dateFilterStr)
                      .length,
                  onDateSelected: _changeSelectedDate,
                ),
                loading: () => const SizedBox(height: 72),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 6),

              // Activity List
              Expanded(
                child: activitiesAsync.when(
                  data: (activities) {
                    final filtered = activities
                        .where((act) => act.tarih == dateFilterStr)
                        .toList();
                    _pruneSelectionAfterBuild(
                      filtered.map((activity) => activity.id),
                    );

                    if (filtered.isEmpty) {
                      final formattedDate =
                          DateFormat('dd.MM.yyyy').format(_selectedDateFilter);
                      return Center(
                        child: Text(
                          '$formattedDate tarihine ait faaliyet kaydı bulunamadı.',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    filtered.sort((a, b) {
                      final dateOrder = b.tarih.compareTo(a.tarih);
                      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
                    });
                    final ordered = _applyManualOrder(filtered, dateFilterStr);

                    const listPadding = EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: context.accentOrOlive,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_formatTurkishDay(dateFilterStr)}'
                                  ' • ${ordered.length} faaliyet',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_reorderMode)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              'Kartları tutamaçtan sürükleyerek taşıyın. '
                              'Sıralama bu güne kaydedilir.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        Expanded(
                          child: _reorderMode
                              ? ReorderableListView.builder(
                                  key: const Key('activity-reorder-list'),
                                  padding: listPadding,
                                  buildDefaultDragHandles: false,
                                  itemCount: ordered.length,
                                  onReorderItem: (oldIndex, newIndex) =>
                                      _handleReorder(
                                    ordered,
                                    dateFilterStr,
                                    oldIndex,
                                    newIndex,
                                  ),
                                  itemBuilder: (context, index) {
                                    final act = ordered[index];
                                    return Row(
                                      key: ValueKey<int>(act.id),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Icon(
                                              Icons.drag_indicator_rounded,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildActivityCard(act),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: listPadding,
                                  itemCount: ordered.length,
                                  itemBuilder: (context, index) =>
                                      _buildActivityCard(ordered[index]),
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Hata: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTurkishDay(String isoDate) {
  const months = <String>[
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
  final date = DateTime.parse(isoDate);
  return '${date.day} ${months[date.month - 1]}';
}
