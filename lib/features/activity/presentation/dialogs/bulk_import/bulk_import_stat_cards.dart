import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class BulkImportStatCard extends StatelessWidget {
  const BulkImportStatCard({
    required this.number,
    required this.label,
    required this.icon,
    super.key,
  });

  final int number;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          children: [
            Text(
              '$number',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF556B3F),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BulkImportCompactStatBar extends StatelessWidget {
  const BulkImportCompactStatBar({
    required this.cardCount,
    required this.personnelCount,
    required this.dayCount,
    super.key,
  });

  final int cardCount;
  final int personnelCount;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(icon: Icons.assignment_rounded, text: '$cardCount Kart'),
          Container(height: 14, width: 1, color: context.cardBorderColor),
          _StatChip(icon: Icons.groups_rounded, text: '$personnelCount Personel'),
          Container(height: 14, width: 1, color: context.cardBorderColor),
          _StatChip(icon: Icons.calendar_month_rounded, text: '$dayCount Gün'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF556B3F)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF556B3F),
          ),
        ),
      ],
    );
  }
}
