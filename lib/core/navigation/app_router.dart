import 'package:go_router/go_router.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';
import 'package:personelapp2/features/activity/presentation/pending_approvals_screen.dart';
import 'package:personelapp2/features/auth/presentation/login_screen.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/activity-form',
      builder: (context, state) => const ActivityFormScreen(),
    ),
    GoRoute(
      path: '/pending-approvals',
      builder: (context, state) => const PendingApprovalsScreen(),
    ),
    GoRoute(
      path: '/personnel-management',
      builder: (context, state) => const PersonnelManagementScreen(),
    ),
    GoRoute(
      path: '/monthly-matrix',
      builder: (context, state) => const MonthlyMatrixScreen(),
    ),
    GoRoute(
      path: '/activity-archive',
      builder: (context, state) => const ActivityArchiveScreen(),
    ),
  ],
);
