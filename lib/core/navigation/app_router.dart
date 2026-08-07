import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';
import 'package:personelapp2/features/activity/presentation/pending_approvals_screen.dart';
import 'package:personelapp2/features/auth/presentation/login_screen.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_form_screen.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_preview_screen.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(userSessionProvider);
  return createAppRouter(session: session);
});

GoRouter createAppRouter({UserSessionState? session}) {
  const loginRoute = '/login';
  const adminOnlyRoutes = <String>{'/pending-approvals'};

  return GoRouter(
    initialLocation: loginRoute,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final hasSession = session != null;

      if (!hasSession && location != loginRoute) return loginRoute;
      if (hasSession && location == loginRoute) return '/dashboard';
      if (adminOnlyRoutes.contains(location) && session?.isAdmin != true) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: loginRoute, builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen()),
      GoRoute(
          path: '/activity-form',
          builder: (context, state) => const ActivityFormScreen()),
      GoRoute(
          path: '/pending-approvals',
          builder: (context, state) => const PendingApprovalsScreen()),
      GoRoute(
          path: '/personnel-management',
          builder: (context, state) => const PersonnelManagementScreen()),
      GoRoute(
          path: '/monthly-matrix',
          builder: (context, state) => const MonthlyMatrixScreen()),
      GoRoute(
          path: '/activity-archive',
          builder: (context, state) => const ActivityArchiveScreen()),
      GoRoute(
          path: '/temgundrap',
          builder: (context, state) => const TemgundrapScreen()),
      GoRoute(
        path: '/temgundrap/form',
        builder: (context, state) => TemgundrapFormScreen(
          initialDocument: state.extra as TemgundrapDocument?,
          initialDate: DateTime.tryParse(
            state.uri.queryParameters['date'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/temgundrap/preview',
        builder: (context, state) => TemgundrapPreviewScreen(
          document: state.extra! as TemgundrapDocument,
        ),
      ),
    ],
  );
}
