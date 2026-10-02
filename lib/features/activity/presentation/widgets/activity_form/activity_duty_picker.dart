import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';

const inheritCommonDutyValue = '__inherit_common_duty__';

Future<String?> showActivityDutyPicker(
  BuildContext context, {
  required String title,
  required List<String> duties,
  required String keyPrefix,
  String? inheritLabel,
}) {
  final content = _DutyPickerContent(
    title: title,
    duties: duties,
    keyPrefix: keyPrefix,
    inheritLabel: inheritLabel,
  );
  if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: .78, child: content),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: content,
      ),
    ),
  );
}

class _DutyPickerContent extends StatelessWidget {
  const _DutyPickerContent({
    required this.title,
    required this.duties,
    required this.keyPrefix,
    required this.inheritLabel,
  });

  final String title;
  final List<String> duties;
  final String keyPrefix;
  final String? inheritLabel;

  @override
  Widget build(BuildContext context) {
    final itemCount = duties.length + (inheritLabel == null ? 0 : 1);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isInherit = inheritLabel != null && index == 0;
                  final duty = isInherit
                      ? inheritCommonDutyValue
                      : duties[index - (inheritLabel == null ? 0 : 1)];
                  return ListTile(
                    key: ValueKey('$keyPrefix-$duty'),
                    leading: Icon(
                      isInherit
                          ? Icons.refresh_rounded
                          : Icons.assignment_ind_outlined,
                      color: context.accentOrOlive,
                    ),
                    title: Text(isInherit ? inheritLabel! : duty),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, duty),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
