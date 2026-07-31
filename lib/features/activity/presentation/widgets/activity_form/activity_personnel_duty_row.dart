import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';

class ActivityPersonnelDutyRow extends StatelessWidget {
  const ActivityPersonnelDutyRow({
    required this.personnel,
    required this.currentSelection,
    required this.availableDuties,
    required this.adminOnlyDuties,
    required this.onDutyChanged,
    super.key,
  });

  final PersonelTableData personnel;
  final String? currentSelection;
  final List<String> availableDuties;
  final List<String> adminOnlyDuties;
  final ValueChanged<String?> onDutyChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${personnel.rutbe} ${personnel.adSoyad}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Birlik: ${personnel.birlik}',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsiveValue(
                mobile: 135,
                tablet: 180,
                desktop: 220,
              ),
            ),
            child: DropdownButton<String>(
              value: currentSelection,
              isDense: true,
              isExpanded: true,
              hint: Text(
                'SEÇİNİZ',
                style: TextStyle(
                  color: context.accentOrOlive,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              items: availableDuties.map((d) {
                final isAdminOnly = adminOnlyDuties.contains(d);
                return DropdownMenuItem<String>(
                  value: d,
                  child: Text(
                    d,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isAdminOnly ? FontWeight.bold : FontWeight.normal,
                      color: isAdminOnly
                          ? context.accentOrOlive
                          : context.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onDutyChanged,
            ),
          ),
        ],
      ),
    );
  }
}
