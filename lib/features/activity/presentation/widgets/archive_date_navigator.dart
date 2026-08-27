import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ArchiveDateNavigator extends StatelessWidget {
  const ArchiveDateNavigator({
    required this.selectedDate,
    required this.activityCount,
    required this.onDateSelected,
    super.key,
  });

  final DateTime selectedDate;
  final int activityCount;
  final ValueChanged<DateTime> onDateSelected;

  static const _months = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: context.cardBorderColor)),
      ),
      child: Row(
        children: [
          _DateArrowButton(
            key: const Key('archive-previous-day'),
            icon: Icons.chevron_left_rounded,
            tooltip: 'Önceki gün',
            onPressed: () =>
                onDateSelected(selectedDate.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${selectedDate.day} ${_months[selectedDate.month - 1]}',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$activityCount faaliyet',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _DateArrowButton(
            key: const Key('archive-next-day'),
            icon: Icons.chevron_right_rounded,
            tooltip: 'Sonraki gün',
            onPressed: () =>
                onDateSelected(selectedDate.add(const Duration(days: 1))),
          ),
        ],
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
        color: context.accentOrOlive.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.cardBorderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: context.accentOrOlive, size: 28),
          ),
        ),
      ),
    );
  }
}
