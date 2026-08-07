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
    final dateFormatted = DateFormat('dd MMMM yyyy', 'tr_TR').format(selectedDate);
    final selectedActivity = activityNameController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionRow(
            key: const Key('activity-date-row'),
            icon: Icons.calendar_month_rounded,
            label: 'Tarih',
            value: dateFormatted,
            onTap: onPickDate,
          ),
          Divider(height: 1, color: context.cardBorderColor),
          _ActionRow(
            key: const Key('activity-name-field'),
            icon: Icons.shield_outlined,
            label: 'Faaliyet',
            value: selectedActivity.isEmpty ? 'Faaliyet seçin' : selectedActivity,
            showError: showNameError,
            onTap: () => _showActivityPicker(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showActivityPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Faaliyet Seç',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...templates.map((template) {
                final isOther = template == 'Diğer';
                final selected = activityNameController.text.trim() == template;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? context.accentSubtleBg
                          : context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isOther ? Icons.edit_rounded : Icons.shield_outlined,
                      color: context.accentOrOlive,
                    ),
                  ),
                  title: Text(
                    template,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle_rounded, color: context.accentOrOlive)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    if (isOther) {
                      _showCustomActivityDialog(context);
                    } else {
                      onTemplateSelected(template);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomActivityDialog(BuildContext context) async {
    final controller = TextEditingController(text: activityNameController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faaliyet adı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Faaliyet adını yazın',
          ),
          onChanged: onNameChanged,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (value == null || value.isEmpty) return;
    activityNameController.text = value;
    onNameChanged(value);
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showError = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.accentSubtleBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: context.accentOrOlive),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textStyleSecondary.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: showError ? context.rejectedColor : null,
                    ),
                  ),
                  if (showError)
                    Text(
                      'Faaliyet adı zorunludur',
                      style: TextStyle(fontSize: 12, color: context.rejectedColor),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 30),
          ],
        ),
      ),
    );
  }
}
