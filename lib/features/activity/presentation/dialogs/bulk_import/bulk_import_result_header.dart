import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class BulkImportResultHeader extends StatelessWidget {
  const BulkImportResultHeader(
      {required this.added,
      required this.skipped,
      required this.activityContext,
      super.key});
  final int added;
  final int skipped;
  final String activityContext;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentOrOlive;
    final statusColor = skipped > 0 ? context.pendingColor : accent;
    final status = added == 0
        ? 'Yeni personel eklenmedi'
        : skipped > 0
            ? 'Kısmen tamamlandı'
            : 'Tamamlandı';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
          child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: context.textMuted,
                  borderRadius: BorderRadius.circular(8)))),
      Text('Aktarım sonucu',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(24)),
          child: Text(status,
              style:
                  TextStyle(color: statusColor, fontWeight: FontWeight.w700))),
      const SizedBox(height: 8),
      Text(activityContext, style: TextStyle(color: context.textSecondary)),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: IntrinsicHeight(
              child: Row(children: [
            _metric(
                context, added, 'Eklendi', Icons.check_circle_outline, accent),
            VerticalDivider(color: context.cardBorderColor),
            _metric(
                context, skipped, 'Atlandı', Icons.block, context.pendingColor),
          ]))),
    ]);
  }

  Widget _metric(BuildContext context, int count, String label, IconData icon,
          Color color) =>
      Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 10),
        Flexible(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('$count',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: context.textSecondary)),
            ])),
      ]));
}
