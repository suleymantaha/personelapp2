import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

/// Paste content is the only primary task; rarely used audit settings
/// remain available behind an explicit disclosure.
class BulkImportInputSection extends StatelessWidget {
  const BulkImportInputSection({
    required this.textController,
    required this.keepAuditText,
    required this.onKeepAuditTextChanged,
    required this.isMobile,
    required this.isKeyboardVisible,
    required this.isParsing,
    required this.onProcessText,
    super.key,
  });

  final TextEditingController textController;
  final bool keepAuditText;
  final ValueChanged<bool> onKeepAuditTextChanged;
  final bool isMobile;
  final bool isKeyboardVisible;
  final bool isParsing;
  final VoidCallback onProcessText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.bulkImportInputRawTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (!isKeyboardVisible) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.bulkImportInputRawSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 14, height: 1.4),
              cursorColor: context.accentOrOlive,
              scrollPadding: const EdgeInsets.only(bottom: 80),
              decoration: InputDecoration(
                hintText: context.l10n.bulkImportInputPlaceholderShort,
                hintStyle: TextStyle(color: context.textMuted),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.accentOrOlive, width: 1.5),
                ),
              ),
            ),
          ),
          if (!isKeyboardVisible)
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Gelişmiş seçenekler',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              initiallyExpanded: keepAuditText,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: keepAuditText,
                  onChanged: onKeepAuditTextChanged,
                  title: Text(
                    context.l10n.bulkImportKeepAuditTextTitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    context.l10n.bulkImportKeepAuditTextDesc,
                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
                ),
              ],
            ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: isParsing ? null : onProcessText,
              icon: isParsing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                context.l10n.bulkImportParseAndCreateCards,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: context.onAccentOrOlive,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
