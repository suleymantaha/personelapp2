import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

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
      padding: EdgeInsets.all(isMobile ? (isKeyboardVisible ? 12 : 16) : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: context.accentOrOlive,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Ham Metni Yapıştırın:',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (!isKeyboardVisible) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.accentOrOlive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tarih, görev türü ve personel listesini içeren mesajı '
                'olduğu gibi yapıştırabilirsiniz.',
                style: TextStyle(
                  color: context.accentOrOlive,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
          SizedBox(height: isKeyboardVisible ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ham metni yerel denetim kaydında sakla',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Varsayılan kapalıdır; veri yalnızca bu cihazda tutulur.',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Switch(
                value: keepAuditText,
                onChanged: onKeepAuditTextChanged,
              ),
            ],
          ),
          SizedBox(height: isKeyboardVisible ? 4 : 6),
          Expanded(
            child: TextField(
              controller: textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 13, height: 1.4),
              cursorColor: context.accentOrOlive,
              scrollPadding: const EdgeInsets.only(bottom: 80),
              decoration: InputDecoration(
                hintText: 'Mesaj metnini buraya yapıştırın…',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.accentOrOlive,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isParsing ? null : onProcessText,
              icon: isParsing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Metni Ayrıştır ve Kartları Oluştur',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: Colors.white,
                elevation: 2,
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
