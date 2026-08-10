part of 'bulk_import_preview_section.dart';

enum _PreviewFilter { problems, all, ready }

class _CorrectnessPanel extends StatelessWidget {
  const _CorrectnessPanel({
    required this.cardCount,
    required this.personnelCount,
    required this.dayCount,
    required this.criticalCount,
    required this.reviewCount,
    required this.actionCount,
    required this.hasBlocking,
    required this.compact,
    required this.onClearAll,
    required this.onStartWizard,
    this.onConfirmAllSuggestions,
  });

  final int cardCount;
  final int personnelCount;
  final int dayCount;
  final int criticalCount;
  final int reviewCount;
  final int actionCount;
  final bool hasBlocking;
  final bool compact;
  final VoidCallback onClearAll;
  final VoidCallback? onStartWizard;
  final VoidCallback? onConfirmAllSuggestions;

  @override
  Widget build(BuildContext context) {
    final actionText = actionCount == 0
        ? 'Tüm kontroller tamam'
        : 'Kaydetmeden önce $actionCount işlem tamamlanmalı';
    if (compact) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          children: [
            const Text(
              'Doğruluk Paneli',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            if (hasBlocking) ...[
              InkWell(
                onTap: onStartWizard,
                borderRadius: BorderRadius.circular(999),
                child: _StatusPill(
                  text: 'Kaydedilemiyor',
                  color: context.rejectedColor,
                  background: context.rejectedBgColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (criticalCount > 0 || reviewCount > 0) ...[
              Text(
                [
                  if (criticalCount > 0) '$criticalCount kritik hata',
                  if (reviewCount > 0) '$reviewCount inceleme',
                ].join(' • '),
                style: TextStyle(
                  color: hasBlocking
                      ? context.rejectedColor
                      : context.pendingColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.assignment_rounded,
                      value: '$cardCount',
                      label: 'kart',
                      color: context.accentOrOlive,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.groups_rounded,
                      value: '$personnelCount',
                      label: 'personel',
                      color: context.accentOrOlive,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.calendar_month_rounded,
                      value: '$dayCount',
                      label: 'gün',
                      color: context.accentOrOlive,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.error_rounded,
                      value: '$criticalCount',
                      label: 'kritik',
                      color: context.rejectedColor,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.info_rounded,
                      value: '$reviewCount',
                      label: 'inceleme',
                      color: context.pendingColor,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                actionText,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: hasBlocking
                      ? context.rejectedColor
                      : context.approvedColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onConfirmAllSuggestions != null) ...[
              const SizedBox(width: 6),
              FilledButton.icon(
                key: const Key('bulk-confirm-all-suggestions'),
                onPressed: onConfirmAllSuggestions,
                icon: const Icon(Icons.done_all_rounded, size: 14),
                label: const Text(
                  'Tümünü Onayla',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.approvedColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
            IconButton(
              onPressed: onClearAll,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Tümünü Temizle',
            ),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 8 : 12, 8, compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Doğruluk Paneli',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hasBlocking)
                      InkWell(
                        onTap: onStartWizard,
                        borderRadius: BorderRadius.circular(999),
                        child: _StatusPill(
                          text: 'Kaydedilemiyor',
                          color: context.rejectedColor,
                          background: context.rejectedBgColor,
                        ),
                      ),
                    if (onConfirmAllSuggestions != null)
                      FilledButton.icon(
                        key: const Key('bulk-confirm-all-suggestions'),
                        onPressed: onConfirmAllSuggestions,
                        icon: const Icon(Icons.done_all_rounded, size: 14),
                        label: const Text(
                          'Tümünü Onayla',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.approvedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClearAll,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: 'Tümünü Temizle',
              ),
            ],
          ),
          Text(
            actionText,
            style: TextStyle(
              color:
                  hasBlocking ? context.rejectedColor : context.approvedColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (criticalCount > 0 || reviewCount > 0) ...[
            const SizedBox(height: 3),
            Text(
              [
                if (criticalCount > 0) '$criticalCount kritik hata',
                if (reviewCount > 0) '$reviewCount inceleme',
              ].join(' • '),
              style: TextStyle(
                color:
                    hasBlocking ? context.rejectedColor : context.pendingColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.assignment_rounded,
                  value: '$cardCount',
                  label: 'kart',
                  color: context.accentOrOlive,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.groups_rounded,
                  value: '$personnelCount',
                  label: 'personel',
                  color: context.accentOrOlive,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.calendar_month_rounded,
                  value: '$dayCount',
                  label: 'gün',
                  color: context.accentOrOlive,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.error_rounded,
                  value: '$criticalCount',
                  label: 'kritik',
                  color: context.rejectedColor,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  icon: Icons.info_rounded,
                  value: '$reviewCount',
                  label: 'inceleme',
                  color: context.pendingColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
