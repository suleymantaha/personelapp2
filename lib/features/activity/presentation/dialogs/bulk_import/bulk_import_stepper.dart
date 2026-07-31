import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class BulkImportStepper extends StatelessWidget {
  const BulkImportStepper({
    required this.currentStep,
    required this.hasBlocks,
    required this.onStepTapped,
    super.key,
  });

  final int currentStep;
  final bool hasBlocks;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final steps = ['Yapıştır', 'Önizleme', 'Kaydet'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            GestureDetector(
              onTap: () {
                if (i <= currentStep || (i == 1 && hasBlocks)) {
                  onStepTapped(i);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                              : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: i < currentStep
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == currentStep
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == currentStep
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i == currentStep
                          ? const Color(0xFF556B3F)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
