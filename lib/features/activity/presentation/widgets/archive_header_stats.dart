import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ArchiveHeaderStats extends StatelessWidget {
  const ArchiveHeaderStats({
    required this.isAdmin,
    required this.pendingCount,
    required this.totalActivitiesCount,
    required this.selectedDateStr,
    required this.onExportRequested,
    super.key,
  });

  final bool isAdmin;
  final int pendingCount;
  final int totalActivitiesCount;
  final String? selectedDateStr;
  final VoidCallback onExportRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 3),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.cardBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title & concise metrics row
          Row(
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.military_tech,
                color: context.accentOrOlive,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAdmin ? 'KONTROL MERKEZİ' : 'TİM ARŞİVİ',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Metric Badges
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.accentOrOlive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalActivitiesCount Kayıt',
                  style: TextStyle(
                    color: context.accentOrOlive,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              if (isAdmin && pendingCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.pendingColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pendingCount Bekliyor',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: context.onAccentOrOlive,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text(
                'Dışa Aktar / Yazdır',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: onExportRequested,
            ),
          ),
        ],
      ),
    );
  }
}
