import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ArchiveHeaderStats extends StatelessWidget {
  const ArchiveHeaderStats({
    required this.isAdmin,
    required this.pendingCount,
    required this.totalActivitiesCount,
    required this.selectedDateStr,
    required this.onExportMasterExcel,
    super.key,
  });

  final bool isAdmin;
  final int pendingCount;
  final int totalActivitiesCount;
  final String? selectedDateStr;
  final VoidCallback onExportMasterExcel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.headerBg, context.headerBgSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.4 : 0.15,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                radius: 20,
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.military_tech,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? 'YÖNETİCİ KONTROL MERKEZİ' : 'TİM KOMUTANLIĞI SÜZGECİ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      isAdmin
                          ? 'Tüm timlerin günlük kayıtları burada toplanır'
                          : 'Sadece timinize ait faaliyetler gösterilmektedir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin && pendingCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.pendingColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingCount Onay Bekliyor',
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: context.onAccentOrOlive,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.file_download),
              label: Text(
                selectedDateStr != null
                    ? "$selectedDateStr TARİHLİ FAALİYETLERİ TEK EXCEL'E AKTAR"
                    : "GÜNLÜK TÜM FAALİYETLERİ TEK EXCEL'E AKTAR",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: onExportMasterExcel,
            ),
          ),
        ],
      ),
    );
  }
}
