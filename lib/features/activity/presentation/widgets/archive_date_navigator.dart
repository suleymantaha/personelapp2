import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

/// A compact, centered date control designed to live in the archive AppBar.
class ArchiveDateNavigator extends StatelessWidget {
  const ArchiveDateNavigator({
    required this.selectedDate,
    required this.activityCount,
    required this.onDateSelected,
    this.onCalendarTap,
    super.key,
  });

  final DateTime selectedDate;
  final int activityCount;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 7),
        child: Row(
          children: [
            _DateArrowButton(
              key: const Key('archive-previous-day'),
              icon: Icons.chevron_left_rounded,
              tooltip: context.l10n.archivePreviousDayTooltip,
              onPressed: () => onDateSelected(
                selectedDate.subtract(const Duration(days: 1)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: Material(
                  color: context.accentOrOlive.withValues(alpha: 0.045),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: context.cardBorderColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    key: const Key('archive-calendar-date-button'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: onCalendarTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: context.accentOrOlive,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('d MMMM', 'tr_TR').format(selectedDate),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  context.l10n.archiveActivityCount(activityCount),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _DateArrowButton(
              key: const Key('archive-next-day'),
              icon: Icons.chevron_right_rounded,
              tooltip: context.l10n.archiveNextDayTooltip,
              onPressed: () => onDateSelected(
                selectedDate.add(const Duration(days: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateArrowButton extends StatelessWidget {
  const _DateArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: context.accentOrOlive.withValues(alpha: 0.055),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.cardBorderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            width: 38,
            height: 42,
            child: Icon(icon, color: context.accentOrOlive, size: 25),
          ),
        ),
      ),
    );
  }
}
