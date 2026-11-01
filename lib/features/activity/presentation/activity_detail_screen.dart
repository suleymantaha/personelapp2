import 'widgets/team_selection_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

typedef ActivityDetailActions = Widget Function(BuildContext, WidgetRef,
    GunlukFaaliyetTableData, List<FaaliyetPersonelAtamaTableData>);

/// A route owns the activity context; live database streams keep edits current.
class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen(
      {super.key,
      required this.activityId,
      required this.actionsBuilder,
      this.selectedSquadId});
  final int activityId;
  final int? selectedSquadId;
  final ActivityDetailActions actionsBuilder;

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  Widget? _toolbar;
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<GunlukFaaliyetTableData?>(
      stream: (db.select(db.gunlukFaaliyetTable)
            ..where((t) => t.id.equals(widget.activityId)))
          .watchSingleOrNull(),
      builder: (context, activitySnapshot) {
        final activity = activitySnapshot.data;
        if (activity == null) {
          return Scaffold(
              appBar: AppBar(),
              body: Center(
                  child: Text(activitySnapshot.connectionState ==
                          ConnectionState.waiting
                      ? 'Yükleniyor…'
                      : 'Faaliyet artık mevcut değil.')));
        }
        return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
          stream: (db.select(db.faaliyetPersonelAtamaTable)
                ..where((t) => t.faaliyetId.equals(widget.activityId)))
              .watch(),
          builder: (context, snapshot) =>
              NotificationListener<TeamSelectionNotification>(
                  onNotification: (n) {
                    setState(() => _toolbar = n.toolbar);
                    return true;
                  },
                  child: Scaffold(
                    key: const Key('activity-detail-screen'),
                    appBar: AppBar(title: Text(activity.faaliyetAdi), actions: [
                      if (_toolbar == null &&
                          ref.watch(userSessionProvider)?.isAdmin == true)
                        widget.actionsBuilder(
                            context, ref, activity, snapshot.data ?? []),
                    ]),
                    bottomNavigationBar: _toolbar,
                    body: SafeArea(
                        child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              DateFormat('d MMMM yyyy', 'tr')
                                  .format(DateTime.parse(activity.tarih)),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ActivityAssignmentDetails(
                              activity: activity,
                              assignments: snapshot.data ?? [],
                              selectedSquadId: widget.selectedSquadId,
                              usePersistentToolbar: true,
                              selectionActive: _toolbar != null),
                        ],
                      ),
                    )),
                  )),
        );
      },
    );
  }
}
