import 'package:flutter/material.dart';
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

  bool _isStepEnabled(int stepIndex) {
    if (stepIndex <= currentStep) return true;
    if (stepIndex == 1) return hasBlocks;
    if (stepIndex == 2) return canProceedToSave;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Yapıştır', 'Önizleme', 'Kaydet'];
    final accentColor = context.accentOrOlive;
    final approvedColor = context.approvedColor;
    final disabledLineColor = context.cardBorderColor;
    final disabledTextColor = context.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  height: 2,
                  color: i <= currentStep ? accentColor : disabledLineColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onTap: () {
                  if (_isStepEnabled(i)) {
                    onStepTapped(i);
                  }
                },
                child: Tooltip(
                  message: i == 2 && !canProceedToSave && currentStep < 2
                      ? 'Tüm kart sorunları çözülünce kaydet adımı açılır'
                      : steps[i],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < currentStep
                                  ? accentColor
                                  : i == currentStep
                                      ? accentColor
                                      : (i == 2 && canProceedToSave)
                                          ? approvedColor.withAlpha(40)
                                          : disabledLineColor,
                              border: i == 2 && canProceedToSave && currentStep < 2
                                  ? Border.all(
                                      color: approvedColor, width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: i < currentStep
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: i == currentStep
                                            ? context.customColors.onAccentOrOlive
                                            : i == 2 && canProceedToSave
                                                ? approvedColor
                                                : disabledTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                          if (i == 2 && !canProceedToSave && currentStep < 2)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: disabledTextColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white,
                                  size: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == currentStep ||
                                  (i == 2 && canProceedToSave)
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
            ),
            if (i < steps.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
