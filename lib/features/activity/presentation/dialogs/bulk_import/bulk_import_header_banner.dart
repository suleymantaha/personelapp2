import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';

class BulkImportHeaderBanner extends StatelessWidget {
  const BulkImportHeaderBanner({
    required this.isKeyboardVisible,
    required this.onClose,
    this.onOpenMemory,
    super.key,
  });

  final bool isKeyboardVisible;
  final VoidCallback? onClose;
  final VoidCallback? onOpenMemory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isKeyboardVisible ? 10 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.accentOrOlive,
            context.accentOrOlive.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.onAccentOrOlive.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.paste_rounded,
              color: context.onAccentOrOlive,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.bulkImportHeaderTitle,
                  style: TextStyle(
                    fontSize: isKeyboardVisible ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: context.onAccentOrOlive,
                  ),
                ),
                if (!isKeyboardVisible) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.bulkImportHeaderSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onAccentOrOlive,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onOpenMemory != null)
            IconButton(
              tooltip: context.l10n.bulkImportManageMemoryTooltip,
              icon: Icon(
                Icons.psychology_rounded,
                color: context.onAccentOrOlive,
              ),
              onPressed: onOpenMemory,
            ),
          IconButton(
            tooltip: context.l10n.bulkImportCloseTooltip,
            icon: Icon(Icons.close, color: context.onAccentOrOlive),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
