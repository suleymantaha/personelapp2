import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/features/personnel/domain/personnel_display_order.dart';
import 'widgets/personnel_inline_order_editor.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/bulk_personnel_import_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_form_dialog.dart';

part 'personnel_management_actions.dart';
part 'squad_management_actions.dart';
part 'personnel_order_actions.dart';
part 'personnel_management_app_bar.dart';
part 'personnel_management_filters.dart';

part 'personnel_group_list.dart';
part 'personnel_member_tile.dart';
part 'personnel_member_menu.dart';

class PersonnelManagementScreen extends ConsumerStatefulWidget {
  const PersonnelManagementScreen({super.key});
  @override
  ConsumerState<PersonnelManagementScreen> createState() =>
      _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState
    extends ConsumerState<PersonnelManagementScreen> {
  bool _ordering = false;
  bool _searchVisible = false;
  final _expandedTeamIds = <int?>{};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updatePersonnelView(VoidCallback callback) => setState(callback);
  void _toggleSearch() => setState(() {
        _searchVisible = !_searchVisible;
        if (!_searchVisible) {
          _searchController.clear();
          _searchQuery = '';
          FocusScope.of(context).unfocus();
        }
      });
  @override
  Widget build(BuildContext context) {
    if (_ordering) return _buildOrderScaffold();
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;
    final personnel = ref.watch(allPersonnelProvider);
    final squads = ref.watch(allSquadsProvider);
    return Scaffold(
      appBar: _buildPersonnelAppBar(context: context, isAdmin: isAdmin),
      body: SingleChildScrollView(
          child: ResponsiveCenter(
              maxWidth: AppSpacing.readableContentWidth,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildPersonnelFilters(
                        context: context,
                        isAdmin: isAdmin,
                        session: session,
                        squadsAsync: squads),
                    personnel.when(
                        data: (people) => squads.when(
                            data: (teams) =>
                                _buildTeamList(people, teams, session),
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (error, stack) => Text(context.l10n
                                .commonErrorWithDetails(error.toString()))),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text(context.l10n
                            .commonErrorWithDetails(error.toString()))),
                    const SizedBox(height: 24),
                  ]))),
    );
  }
}
