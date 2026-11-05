import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'bulk_import_confirm_section.dart';
import 'bulk_import_outcome_list.dart';
import 'bulk_import_result_header.dart';

/// Shown only after the enclosing import transaction has committed.
Future<void> showBulkImportResult(
        {required BuildContext context,
        required List<ActivityImportOutcome> outcomes,
        required int addedCount,
        required int skippedCount,
        required String fallbackContext}) =>
    showModalBottomSheet<void>(
        context: context,
        useRootNavigator: false,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            side: BorderSide(color: context.cardBorderColor)),
        builder: (_) => BulkImportResultSheet(
            outcomes: outcomes,
            addedCount: addedCount,
            skippedCount: skippedCount,
            fallbackContext: fallbackContext));

class BulkImportResultSheet extends StatelessWidget {
  const BulkImportResultSheet(
      {required this.outcomes,
      required this.addedCount,
      required this.skippedCount,
      required this.fallbackContext,
      super.key});
  final List<ActivityImportOutcome> outcomes;
  final int addedCount;
  final int skippedCount;
  final String fallbackContext;

  @override
  Widget build(BuildContext context) {
    final skipped =
        outcomes.where((o) => o.status != ActivityImportStatus.added).toList();
    final added =
        outcomes.where((o) => o.status == ActivityImportStatus.added).toList();
    final contexts = outcomes
        .map((o) => '${o.activityName} · '
            '${BulkImportConfirmSection.displayDate(o.date)}')
        .toSet();
    final activityContext = contexts.isEmpty
        ? fallbackContext
        : contexts.length == 1
            ? contexts.single
            : '${contexts.length} faaliyet / tarih';
    return PopScope(
        canPop: false,
        child: SafeArea(
            top: false,
            child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .9,
                child: DefaultTabController(
                    length: 2,
                    initialIndex: skippedCount > 0 ? 0 : 1,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: _resultContent(context, added, skipped,
                                      activityContext)),
                              Divider(color: context.cardBorderColor),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified_user_outlined,
                                            color: context.accentOrOlive,
                                            size: 23),
                                        const SizedBox(width: 8),
                                        const Flexible(
                                            child: Text(
                                                'Mevcut kayıtlar korunuyor.')),
                                      ])),
                              SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                      key: const Key('bulk-import-result-done'),
                                      style: FilledButton.styleFrom(
                                          backgroundColor:
                                              context.accentOrOlive,
                                          foregroundColor:
                                              context.onStatusColor(
                                                  context.accentOrOlive),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16))),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Tamam'))),
                            ]))))));
  }

  Widget _resultContent(BuildContext context, List<ActivityImportOutcome> added,
      List<ActivityImportOutcome> skipped, String activityContext) {
    final header = BulkImportResultHeader(
        added: addedCount,
        skipped: skippedCount,
        activityContext: activityContext);
    final tabs = TabBar(
        labelColor: context.accentOrOlive,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: context.accentOrOlive,
        tabs: [
          Tab(text: 'Atlananlar ($skippedCount)'),
          Tab(text: 'Eklenenler ($addedCount)'),
        ]);
    final pages = TabBarView(children: [
      _outcomeTab(skipped,
          'Zaten kayıtlı veya aynı gün görev kaydı bulunan personeller eklenmedi.'),
      _outcomeTab(added, 'Görev kaydı başarıyla eklenen personeller.'),
    ]);
    // Large accessibility text needs to scroll the summary as well as the rows.
    if (MediaQuery.textScalerOf(context).scale(14) > 21) {
      return NestedScrollView(
          headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(child: header),
                SliverToBoxAdapter(child: tabs),
              ],
          body: pages);
    }
    return Column(children: [
      header,
      tabs,
      const SizedBox(height: 8),
      Expanded(child: pages)
    ]);
  }

  Widget _outcomeTab(List<ActivityImportOutcome> items, String explanation) =>
      BulkImportOutcomeList(
          outcomes: items,
          description: items.isEmpty ? 'Bu grupta personel yok.' : explanation);
}
