import 'package:drift/drift.dart' show Value;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/matrix/domain/matrix_personnel_order.dart';
import 'package:personelapp2/features/matrix/presentation/widgets/team_duty_calendar_modal.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

part 'monthly_matrix_actions.dart';
part 'monthly_matrix_app_bar.dart';
part 'monthly_matrix_mobile_view.dart';
part 'monthly_matrix_desktop_view.dart';

class MonthlyMatrixScreen extends ConsumerStatefulWidget {
  const MonthlyMatrixScreen({super.key});

  @override
  ConsumerState<MonthlyMatrixScreen> createState() =>
      _MonthlyMatrixScreenState();
}

class _MonthlyMatrixScreenState extends ConsumerState<MonthlyMatrixScreen> {
  DateTime _selectedMonth = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isMobileSearchOpen = false;

  // Her bir timin açık/kapalı durumunu takip eden Set (null = timsiz)
  final Set<int?> _expandedTeamIds = {};

  String _getAbbreviation(MatrixDayCell? cell) => cell?.displayCode ?? '-';

  void _updateState(VoidCallback callback) => setState(callback);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yearMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final personnelAsync = ref.watch(historicalPersonnelProvider);
    final squads = ref.watch(allSquadsProvider).valueOrNull ?? const [];
    final matrixAsync = ref.watch(monthlyMatrixProvider(yearMonthStr));
    final storedSession = ref.watch(userSessionProvider);
    final authorizedTeam = storedSession?.isAdmin == false
      ? ref.watch(commanderAuthorityProvider).valueOrNull : null;
    final session = storedSession != null && !storedSession.isAdmin
      ? UserSessionState(username: storedSession.username,
          role: storedSession.role, timId: authorizedTeam) : storedSession;
    final matrixData = matrixAsync.isLoading
      ? <int, Map<int, MatrixDayCell>>{} : matrixAsync.valueOrNull ?? {};

    final availablePersonnel = personnelAsync.valueOrNull == null
        ? <PersonelTableData>[]
        : _personnelAvailableToSession(personnelAsync.valueOrNull!, session, matrixData);
    final visiblePersonnelCount =
        availablePersonnel.where(_matchesPersonnelSearch).length;

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final onExport = availablePersonnel.isEmpty
        ? null
        : () => _exportMatrix(
              personnel: orderMatrixPersonnel(availablePersonnel, squads),
              matrixData: matrixData,
            );
    final body = personnelAsync.when(
      data: (rawPersonnelList) {
        final filteredPersonnel = _personnelAvailableToSession(
          rawPersonnelList,
          session,
          matrixData,
        ).where(_matchesPersonnelSearch).toList();
        final personnelList = orderMatrixPersonnel(filteredPersonnel, squads);

        if (personnelList.isEmpty) {
          return _buildEmptyPersonnelState(context);
        }

        final squadNames = {
          for (final squad in squads) squad.id: squad.timAdi,
        };

        // Personnel'i tim bazlı grupla
        final groupedPersonnel = <int?, List<PersonelTableData>>{};
        for (final person in personnelList) {
          groupedPersonnel.putIfAbsent(person.timId, () => []).add(person);
        }

        final mobileBody = _buildMonthlyMobileBody(
          context: context,
          groupedPersonnel: groupedPersonnel,
          squadNames: squadNames,
          personnelList: personnelList,
          matrixData: matrixData,
          daysInMonth: daysInMonth,
        );
        if (mobileBody != null) return mobileBody;

        return _buildMonthlyDesktopBody(
          context: context,
          groupedPersonnel: groupedPersonnel,
          squadNames: squadNames,
          personnelList: personnelList,
          matrixData: matrixData,
          daysInMonth: daysInMonth,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Hata: $err')),
    );

    if (MediaQuery.sizeOf(context).width < 680) {
      return Scaffold(
        body: TurkishFlagWatermarkBackground(
          child: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildMobileMatrixAppBar(
                context: context,
                totalPersonnelCount: availablePersonnel.length,
                visiblePersonnelCount: visiblePersonnelCount,
                onExport: onExport,
              ),
            ],
            body: body,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildMatrixAppBar(
        context: context,
        totalPersonnelCount: availablePersonnel.length,
        visiblePersonnelCount: visiblePersonnelCount,
        onExport: onExport,
      ),
      body: TurkishFlagWatermarkBackground(
        child: body,
      ),
    );
  }
}
