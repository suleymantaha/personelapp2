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
                  color: i <= currentStep
                      ? const Color(0xFF556B3F)
                      : Colors.grey.shade300,
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
                                  ? const Color(0xFF556B3F)
                                  : i == currentStep
                                      ? const Color(0xFF556B3F)
                                      : (i == 2 && canProceedToSave)
                                          ? const Color(0xFF16A34A).withAlpha(40)
                                          : Colors.grey.shade300,
                              border: i == 2 && canProceedToSave && currentStep < 2
                                  ? Border.all(
                                      color: const Color(0xFF16A34A), width: 1.5)
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
                                            ? Colors.white
                                            : i == 2 && canProceedToSave
                                                ? const Color(0xFF16A34A)
                                                : Colors.grey.shade600,
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6B7280),
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
                              ? const Color(0xFF556B3F)
                              : i == 2 && canProceedToSave
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey.shade600,
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
