import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class BulkImportStepper extends StatelessWidget {
  const BulkImportStepper({
    required this.currentStep,
    required this.hasBlocks,
    required this.canProceedToSave,
    required this.onStepTapped,
    super.key,
  });

  final int currentStep;
  final bool hasBlocks;
  final bool canProceedToSave;
  final ValueChanged<int> onStepTapped;

  bool _isEnabled(int index) =>
      index <= currentStep ||
      (index == 1 && hasBlocks) ||
      (index == 2 && canProceedToSave);

  @override
  Widget build(BuildContext context) {
    final steps = [
      context.l10n.bulkImportStepPaste,
      context.l10n.bulkImportStepPreview,
      context.l10n.bulkImportStepConfirm,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cardBorderColor)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Divider(
                    thickness: 1.5,
                    color: index <= currentStep
                        ? context.accentOrOlive
                        : context.cardBorderColor,
                  ),
                ),
              ),
            Semantics(
              button: true,
              enabled: _isEnabled(index),
              selected: index == currentStep,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isEnabled(index) ? () => onStepTapped(index) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: index <= currentStep
                          ? context.accentOrOlive
                          : context.cardBorderColor,
                      child: index < currentStep
                          ? Icon(Icons.check_rounded,
                              size: 15, color: context.onAccentOrOlive)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: index == currentStep
                                    ? context.onAccentOrOlive
                                    : context.textMuted,
                              ),
                            ),
                    ),
                    if (index == currentStep) ...[
                      const SizedBox(width: 5),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.accentOrOlive,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
