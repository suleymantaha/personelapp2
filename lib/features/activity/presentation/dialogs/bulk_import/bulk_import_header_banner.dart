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
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.accentOrOlive,
            context.accentOrOlive.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.paste_rounded,
            color: context.onAccentOrOlive,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Metinden Toplu Aktarım',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.onAccentOrOlive,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onOpenMemory != null)
            IconButton(
              tooltip: context.l10n.bulkImportManageMemoryTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                Icons.psychology_rounded,
                color: context.onAccentOrOlive,
                size: 20,
              ),
              onPressed: onOpenMemory,
            ),
          IconButton(
            tooltip: context.l10n.bulkImportCloseTooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.close_rounded,
              color: context.onAccentOrOlive,
              size: 20,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
