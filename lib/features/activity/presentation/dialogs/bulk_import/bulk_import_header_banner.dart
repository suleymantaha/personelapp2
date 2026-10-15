import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

/// Compact navigation bar shared by paste, preview and confirmation.
class BulkImportHeaderBanner extends StatelessWidget {
  const BulkImportHeaderBanner({
    required this.isKeyboardVisible,
    required this.onClose,
    this.onBack,
    this.onOpenMemory,
    super.key,
  });

  final bool isKeyboardVisible;
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final VoidCallback? onOpenMemory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: context.cardBorderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack ?? onClose,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.bulkImportHeaderTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (!isKeyboardVisible)
                  Text(
                    'WhatsApp / Telegram',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'memory') onOpenMemory?.call();
              if (value == 'close') onClose?.call();
            },
            itemBuilder: (context) => [
              if (onOpenMemory != null)
                PopupMenuItem(
                  value: 'memory',
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(context.l10n.bulkImportMemoryButton),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'close',
                enabled: onClose != null,
                child: Row(
                  children: [
                    const Icon(Icons.close_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.bulkImportCloseTooltip),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
