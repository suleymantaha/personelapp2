import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';

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

  bool _isStepEnabled(int stepIndex) {
    if (stepIndex <= currentStep) return true;
    if (stepIndex == 1) return hasBlocks;
    if (stepIndex == 2) return canProceedToSave;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      context.l10n.bulkImportStepPaste,
      context.l10n.bulkImportStepPreview,
      context.l10n.bulkImportStepConfirm,
    ];
    final accentColor = context.accentOrOlive;
    final approvedColor = context.approvedColor;
    final disabledLineColor = context.cardBorderColor;
    final disabledTextColor = context.textMuted;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: context.cardBorderColor),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) ...[
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i <= currentStep ? accentColor : disabledLineColor,
                ),
              ),
            ],
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_isStepEnabled(i)) {
                  onStepTapped(i);
                }
              },
              child: Tooltip(
                message: i == 2 && !canProceedToSave && currentStep < 2
                    ? 'Tüm kart sorunları çözülünce kaydet adımı açılır'
                    : steps[i],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < currentStep
                                ? accentColor
                                : i == currentStep
                                    ? accentColor
                                    : (i == 2 && canProceedToSave)
                                        ? approvedColor.withAlpha(40)
                                        : disabledLineColor,
                            border: i == 2 &&
                                    canProceedToSave &&
                                    currentStep < 2
                                ? Border.all(color: approvedColor, width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: i < currentStep
                                ? Icon(Icons.check,
                                    color: context.onAccentOrOlive, size: 11)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: i == currentStep
                                          ? context
                                              .customColors.onAccentOrOlive
                                          : i == 2 && canProceedToSave
                                              ? approvedColor
                                              : disabledTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                          ),
                        ),
                        if (i == 2 && !canProceedToSave && currentStep < 2)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: disabledTextColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                color: context.onAccentOrOlive,
                                size: 7,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            i == currentStep || (i == 2 && canProceedToSave)
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color: i == currentStep
                            ? accentColor
                            : i == 2 && canProceedToSave
                                ? approvedColor
                                : disabledTextColor,
                      ),
                    ),
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
