import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/navigation/app_routes.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';
import 'package:personelapp2/features/activity/presentation/pending_approvals_screen.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_screen.dart';
import 'package:personelapp2/features/auth/presentation/login_screen.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_form_screen.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_preview_screen.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_screen.dart';

export 'app_navigator.dart';
export 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(userSessionProvider);
  return createAppRouter(session: session);
});

GoRouter createAppRouter({UserSessionState? session}) {
  const adminOnlyRoutes = <String>{AppRoutes.pendingApprovals};

  return GoRouter(
    initialLocation: session != null ? AppRoutes.dashboard : AppRoutes.login,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final hasSession = session != null;

      if (!hasSession && location != AppRoutes.login) return AppRoutes.login;
      if (hasSession && location == AppRoutes.login) return AppRoutes.dashboard;
      if (adminOnlyRoutes.contains(location) && session?.isAdmin != true) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppNotificationHost(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.activityForm,
            builder: (context, state) => const ActivityFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.activityAssignmentPreview,
            redirect: (context, state) {
              if (state.extra is! ActivityAssignmentPreviewArgs) {
                return AppRoutes.dashboard;
              }
              return null;
            },
            builder: (context, state) {
              final args = state.extra as ActivityAssignmentPreviewArgs;
              return ActivityAssignmentPreviewScreen(
                activityName: args.activityName,
                date: args.date,
                preview: args.preview,
                requiresAdminApproval: args.requiresAdminApproval,
                onConfirm: args.onConfirm,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.pendingApprovals,
            builder: (context, state) => const PendingApprovalsScreen(),
          ),
          GoRoute(
            path: AppRoutes.personnelManagement,
            builder: (context, state) => const PersonnelManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.monthlyMatrix,
            builder: (context, state) => const MonthlyMatrixScreen(),
          ),
          GoRoute(
            path: AppRoutes.activityArchive,
            builder: (context, state) => const ActivityArchiveScreen(),
          ),
          GoRoute(
            path: AppRoutes.rosterOutput,
            builder: (context, state) {
              final initialDate = state.uri.queryParameters['date'] ??
                  DateFormat('yyyy-MM-dd').format(DateTime.now());
              final squadIdStr = state.uri.queryParameters['squadId'];
              final selectedSquadId = squadIdStr != null ? int.tryParse(squadIdStr) : null;
              return RosterOutputScreen(
                initialDate: initialDate,
                selectedSquadId: selectedSquadId,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.rosterOutputPreview,
            redirect: (context, state) {
              if (state.extra is! RosterOutputPreviewArgs) {
                return AppRoutes.rosterOutput;
              }
              return null;
            },
            builder: (context, state) {
              final args = state.extra as RosterOutputPreviewArgs;
              return RosterOutputPreviewScreen(
                date: args.date,
                sources: args.sources,
                rows: args.rows,
                loadRows: args.loadRows,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.temgundrap,
            builder: (context, state) => const TemgundrapScreen(),
          ),
          GoRoute(
            path: AppRoutes.temgundrapForm,
            builder: (context, state) => TemgundrapFormScreen(
              initialDocument: state.extra as TemgundrapDocument?,
              initialDate: DateTime.tryParse(
                state.uri.queryParameters['date'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.temgundrapPreview,
            redirect: (context, state) {
              if (state.extra is! TemgundrapDocument) {
                return AppRoutes.temgundrap;
              }
              return null;
            },
            builder: (context, state) => TemgundrapPreviewScreen(
              document: state.extra as TemgundrapDocument,
            ),
          ),
        ],
      ),
    ],
  );
}
