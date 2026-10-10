import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
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
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/services/temgundrap_activity_converter.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

part 'activity_archive_actions.dart';

class ActivityArchiveScreen extends ConsumerStatefulWidget {
  const ActivityArchiveScreen({super.key});

  @override
  ConsumerState<ActivityArchiveScreen> createState() =>
      _ActivityArchiveScreenState();
}

class _ActivityArchiveScreenState extends ConsumerState<ActivityArchiveScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _loadManualOrder(DateFormat('yyyy-MM-dd').format(_selectedDateFilter));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    // Returning from Android's external share target can restore the Flutter
    // activity without rebuilding the route. Refresh the live providers so
    // the archive is immediately interactive and reflects any changes.
    ref.invalidate(filteredActivitiesProvider);
    ref.invalidate(allPersonnelProvider);
    ref.invalidate(allSquadsProvider);
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
      if (!mounted) return;
      AppNotifications.warning(context.l10n.activityArchiveOrderSaveFailed);
    }
  }

  Future<void> _resetManualOrder(String date) async {
    try {
      await _orderPreferences.clearOrder(date);
    } on Object {
      if (!mounted) return;
      AppNotifications.warning(context.l10n.activityArchiveOrderResetFailed);
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadedOrderDate = date;
      _manualOrder = const [];
    });
    AppNotifications.info(context.l10n.activityArchiveOrderResetSuccess);
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
    final personnelAsync = ref.watch(historicalPersonnelProvider);
    final squads = squadsAsync.value ?? [];
    final allPersonnel = personnelAsync.value ?? [];
    final personnelList = session == null
        ? <PersonelTableData>[]
        : allPersonnel;

    final dateFilterStr = DateFormat('yyyy-MM-dd').format(_selectedDateFilter);
    final now = DateTime.now();
    final isSelectedToday =
        _selectedDateFilter.year == now.year &&
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
      final hasSelectedSquad =
          _selectedSquadFilter != null &&
          squads.any((squad) => squad.id == _selectedSquadFilter);
      final selectedSquadName = hasSelectedSquad
          ? squads
                .firstWhere((squad) => squad.id == _selectedSquadFilter)
                .timAdi
          : null;
      final squadText = selectedSquadName == null
          ? ''
          : ' • $selectedSquadName';
      final subtitle = context.l10n.activityArchiveExportSubtitle(
        DateFormat('dd.MM.yyyy').format(_selectedDateFilter),
        filteredForDate.length,
        squadText,
      );
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
                tooltip: context.l10n.activityArchiveCloseSelection,
                onPressed: _clearSelection,
              )
            : const AppBackButton(),
        title: Text(
          _selectionMode
              ? context.l10n.activityArchiveSelectedCount(_selectedActivityIds.length)
              : (isAdmin ? context.l10n.activityArchiveTitle : context.l10n.activityArchiveTeamTitle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selectionMode) ...[
            TextButton.icon(
              key: const Key('activity-selection-temgundrap'),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: Text(context.l10n.activityArchiveExportToTemgundrap),
              onPressed: () {
                final selected = (activitiesAsync.value ?? [])
                    .where((act) => _selectedActivityIds.contains(act.id))
                    .toList();
                _exportToTemgundrap(selected, personnelList);
              },
            ),
            IconButton(
              key: const Key('activity-selection-export'),
              icon: const Icon(Icons.ios_share),
              tooltip: context.l10n.activityArchiveExportSelectedTooltip,
              onPressed: () => _showSelectedExportOptions(
                activitiesAsync.value ?? [],
                personnelList,
              ),
            ),
          ]
          else if (!context.isMobile)
            TextButton.icon(
              key: const Key('activity-selection-start'),
              onPressed: () => setState(() => _selectionMode = true),
              icon: const Icon(Icons.checklist),
              label: Text(context.l10n.activityArchiveSelectButton),
            ),
          if (!_selectionMode && context.isMobile)
            PopupMenuButton<String>(
              tooltip: context.l10n.activityArchiveMenuTooltip,
              icon: const Icon(Icons.more_vert_rounded),
              elevation: 5,
              shadowColor: context.shadowColor,
              surfaceTintColor: context.colorScheme.surface,
              shape: modernPopupShape(context),
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
              onSelected: (action) async {
                switch (action) {
                  case 'prepare-output':
                    await AppNavigator.toRosterOutput(
                      context,
                      initialDate: dateFilterStr,
                      selectedSquadId: _selectedSquadFilter,
                    );
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
                ModernMenuHeader<String>(
                  title: context.l10n.activityArchiveMenuHeader,
                  subtitle: context.l10n.activityArchiveMenuSubtitle,
                  icon: Icons.inventory_2_outlined,
                ),
                const PopupMenuDivider(),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'prepare-output',
                    title: context.l10n.activityArchivePrepareOutputTitle,
                    subtitle: context.l10n.activityArchivePrepareOutputSubtitle,
                    icon: Icons.playlist_add_check_rounded,
                  ),
                ),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'export',
                    title: context.l10n.activityArchiveExportPrintTitle,
                    subtitle: context.l10n.activityArchiveExportPrintSubtitle,
                    icon: Icons.ios_share_rounded,
                  ),
                ),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'select',
                    title: context.l10n.activityArchiveSelectOptionTitle,
                    subtitle: context.l10n.activityArchiveSelectOptionSubtitle,
                    icon: Icons.checklist_rounded,
                  ),
                ),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'reorder',
                    title: _reorderMode
                        ? context.l10n.activityArchiveFinishReorder
                        : context.l10n.activityArchiveMoveCards,
                    subtitle: _reorderMode
                        ? context.l10n.activityArchiveExitReorderSubtitle
                        : context.l10n.activityArchiveMoveCardsSubtitle,
                    icon: _reorderMode
                        ? Icons.check_rounded
                        : Icons.swap_vert_rounded,
                  ),
                ),
                if (_manualOrder.isNotEmpty)
                  ModernPopupMenuItem(
                    option: ModernActionOption(
                      value: 'reset-order',
                      title: context.l10n.activityArchiveResetOrder,
                      subtitle: context.l10n.activityArchiveResetOrderSubtitle,
                      icon: Icons.restart_alt_rounded,
                    ),
                  ),
                if (!isSelectedToday)
                  ModernPopupMenuItem(
                    option: ModernActionOption(
                      value: 'today',
                      title: context.l10n.activityArchiveReturnToday,
                      subtitle: context.l10n.activityArchiveReturnTodaySubtitle,
                      icon: Icons.today_rounded,
                    ),
                  ),
                if (isAdmin)
                  ModernPopupMenuItem(
                    option: ModernActionOption(
                      value: 'audit',
                      title: context.l10n.activityArchiveAuditTitle,
                      subtitle: context.l10n.activityArchiveAuditSubtitle,
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'date',
                    title: context.l10n.activityArchiveFilterByDate,
                    subtitle: context.l10n.activityArchiveFilterByDateSubtitle,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              key: const Key('activity-prepare-output'),
              tooltip: context.l10n.activityArchivePrepareOutputTitle,
              icon: const Icon(Icons.playlist_add_check_rounded),
              onPressed: () => AppNavigator.toRosterOutput(
                context,
                initialDate: dateFilterStr,
                selectedSquadId: _selectedSquadFilter,
              ),
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              key: const Key('activity-archive-export'),
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: context.l10n.activityArchiveExportPrintTitle,
              onPressed: exportCurrentArchive,
            ),
          if (!_selectionMode && !context.isMobile && !isSelectedToday)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: context.l10n.activityArchiveReturnToday,
              onPressed: () => _changeSelectedDate(DateTime.now()),
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              key: const Key('activity-reorder-toggle'),
              icon: Icon(
                _reorderMode ? Icons.check_rounded : Icons.swap_vert_rounded,
              ),
              tooltip: _reorderMode
                  ? context.l10n.activityArchiveFinishReorder
                  : context.l10n.activityArchiveMoveCards,
              onPressed: () => setState(() => _reorderMode = !_reorderMode),
            ),
          if (!_selectionMode && !context.isMobile && isAdmin)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: context.l10n.activityArchiveAuditTitle,
              onPressed: _showConflictAudit,
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: context.l10n.activityArchiveFilterByDate,
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
                      final formattedDate = DateFormat('dd.MM.yyyy')
                          .format(_selectedDateFilter);
                      return Center(
                        child: Text(
                          context.l10n.activityArchiveNoRecordsFound(formattedDate),
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
                                  context.l10n.activityArchiveDayActivityCount(
                                    _formatTurkishDay(dateFilterStr),
                                    ordered.length,
                                  ),
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
                              context.l10n.activityArchiveReorderHint,
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
                  error: (err, _) => Center(
                    child: Text(
                      context.l10n.commonErrorWithDetails(err.toString()),
                    ),
                  ),
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
  final date = DateTime.parse(isoDate);
  return DateFormat('d MMMM', 'tr_TR').format(date);
}
