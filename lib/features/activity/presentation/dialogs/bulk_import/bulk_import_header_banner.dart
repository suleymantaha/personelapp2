import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class BulkImportHeaderBanner extends StatelessWidget {
  const BulkImportHeaderBanner({
    required this.isKeyboardVisible,
    required this.onClose,
    super.key,
  });

  final bool isKeyboardVisible;
  final VoidCallback onClose;

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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.paste_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metinden Toplu Aktarım',
                  style: TextStyle(
                    fontSize: isKeyboardVisible ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isKeyboardVisible) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'WhatsApp / Telegram nöbet listelerini yapıştırıp akıllı ayrıştırın',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
