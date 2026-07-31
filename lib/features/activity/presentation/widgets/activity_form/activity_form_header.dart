import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ActivityFormHeader extends StatelessWidget {
  const ActivityFormHeader({
    required this.selectedDate,
    required this.onPickDate,
    required this.activityNameController,
    required this.showNameError,
    required this.onNameChanged,
    required this.templates,
    required this.onTemplateSelected,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final TextEditingController activityNameController;
  final bool showNameError;
  final ValueChanged<String> onNameChanged;
  final List<String> templates;
  final ValueChanged<String> onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Column(
            children: [
              InkWell(
                key: const Key('activity-date-row'),
                borderRadius: BorderRadius.circular(12),
                onTap: onPickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.accentSubtleBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: context.accentOrOlive,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faaliyet tarihi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Değiştirmek için dokunun',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('activity-name-field'),
                controller: activityNameController,
                textCapitalization: TextCapitalization.words,
                onChanged: onNameChanged,
                decoration: InputDecoration(
                  labelText: 'Faaliyet adı',
                  hintText: 'Örn. Hazır Kıta',
                  prefixIcon: const Icon(Icons.assignment_outlined),
                  filled: true,
                  fillColor: context.accentSubtleBg,
                  errorText:
                      showNameError ? 'Faaliyet adı zorunludur' : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final template = templates[index];
              final selected =
                  activityNameController.text.trim() == template;
              return ChoiceChip(
                label: Text(template),
                selected: selected,
                showCheckmark: selected,
                onSelected: (_) => onTemplateSelected(template),
              );
            },
          ),
        ),
      ],
    );
  }
}
