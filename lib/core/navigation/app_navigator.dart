import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_routes.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/activity_assignment_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/activity_form_screen.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_screen.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_form_screen.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_preview_screen.dart';

class ActivityAssignmentPreviewArgs {
  const ActivityAssignmentPreviewArgs({
    required this.activityName,
    required this.date,
    required this.preview,
    required this.requiresAdminApproval,
    required this.onConfirm,
  });

  final String activityName;
  final DateTime date;
  final ActivityAssignmentPreview preview;
  final bool requiresAdminApproval;
  final Future<bool> Function() onConfirm;
}

class RosterOutputPreviewArgs {
  const RosterOutputPreviewArgs({
    required this.date,
    required this.sources,
    required this.rows,
    required this.loadRows,
  });

  final String date;
  final List<GunlukFaaliyetTableData> sources;
  final List<MilitaryRosterRow> rows;
  final Future<List<MilitaryRosterRow>> Function() loadRows;
}

abstract final class AppNavigator {
  static void toDashboard(BuildContext context) {
    context.go(AppRoutes.dashboard);
  }

  static void toLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }

  static Future<void> toActivityForm(BuildContext context) {
    if (GoRouter.maybeOf(context) != null) {
      return context.push(AppRoutes.activityForm);
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
    );
  }

  static Future<void> toMonthlyMatrix(BuildContext context) {
    return context.push(AppRoutes.monthlyMatrix);
  }

  static Future<void> toPersonnelManagement(BuildContext context) {
    return context.push(AppRoutes.personnelManagement);
  }

  static Future<void> toPendingApprovals(BuildContext context) {
    return context.push(AppRoutes.pendingApprovals);
  }

  static Future<void> toActivityArchive(BuildContext context) {
    return context.push(AppRoutes.activityArchive);
  }

  static Future<void> toRosterOutput(
    BuildContext context, {
    String? initialDate,
    int? selectedSquadId,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      final params = <String, String>{};
      if (initialDate != null) params['date'] = initialDate;
      if (selectedSquadId != null) params['squadId'] = selectedSquadId.toString();
      final uri = Uri(path: AppRoutes.rosterOutput, queryParameters: params.isEmpty ? null : params);
      return context.push(uri.toString());
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RosterOutputScreen(
          initialDate: initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          selectedSquadId: selectedSquadId,
        ),
      ),
    );
  }

  static Future<void> toRosterOutputPreview(
    BuildContext context, {
    required RosterOutputPreviewArgs args,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      return context.push(AppRoutes.rosterOutputPreview, extra: args);
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RosterOutputPreviewScreen(
          date: args.date,
          sources: args.sources,
          rows: args.rows,
          loadRows: args.loadRows,
        ),
      ),
    );
  }

  static Future<bool?> toActivityAssignmentPreview(
    BuildContext context, {
    required ActivityAssignmentPreviewArgs args,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      return context.push<bool>(AppRoutes.activityAssignmentPreview, extra: args);
    }
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityAssignmentPreviewScreen(
          activityName: args.activityName,
          date: args.date,
          preview: args.preview,
          requiresAdminApproval: args.requiresAdminApproval,
          onConfirm: args.onConfirm,
        ),
      ),
    );
  }

  static Future<void> toTemgundrap(BuildContext context) {
    return context.push(AppRoutes.temgundrap);
  }

  static Future<bool?> toTemgundrapForm(
    BuildContext context, {
    TemgundrapDocument? document,
    DateTime? date,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      final queryDate = date != null
          ? '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          : null;
      final uri = Uri(
        path: AppRoutes.temgundrapForm,
        queryParameters: queryDate != null ? {'date': queryDate} : null,
      );
      return context.push<bool>(uri.toString(), extra: document);
    }
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemgundrapFormScreen(
          initialDocument: document,
          initialDate: date,
        ),
      ),
    );
  }

  static Future<void> toTemgundrapPreview(
    BuildContext context, {
    required TemgundrapDocument document,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      return context.push(AppRoutes.temgundrapPreview, extra: document);
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TemgundrapPreviewScreen(document: document),
      ),
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Güvenli geri dönüş metodu:
  /// Stack'te geri dönülecek sayfa varsa [Navigator.pop] yapar;
  /// Stack boşsa veya doğrudan route'a girildiyse kullanıcıyı kitlemeden Dashboard'a yönlendirir.
  static void popOrDashboard<T>(BuildContext context, [T? result]) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
    } else {
      toDashboard(context);
    }
  }
}

extension AppNavigationContextExtension on BuildContext {
  void popOrDashboard<T>([T? result]) => AppNavigator.popOrDashboard<T>(this, result);
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.color,
    this.onPressed,
  });

  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BackButton(
      color: color,
      onPressed: onPressed ??
          () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.maybePop();
            } else {
              AppNavigator.toDashboard(context);
            }
          },
    );
  }
}
