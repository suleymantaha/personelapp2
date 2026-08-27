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
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.accentOrOlive.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.accentOrOlive.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final identity = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 58,
                decoration: BoxDecoration(
                  color: context.accentOrOlive,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: context.accentOrOlive.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.military_tech,
                  color: context.onAccentOrOlive,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? 'KONTROL MERKEZİ' : 'TİM ARŞİVİ',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 14 : 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      children: [
                        _MetricBadge(label: '$totalActivitiesCount Kayıt'),
                        if (isAdmin && pendingCount > 0)
                          _MetricBadge(
                            label: '$pendingCount Bekliyor',
                            color: context.pendingColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final exportButton = ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(compact ? double.infinity : 154, 46),
              backgroundColor: context.accentOrOlive,
              foregroundColor: context.onAccentOrOlive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.file_download_outlined, size: 20),
            label: const Text(
              'Dışa Aktar / Yazdır',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: onExportRequested,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 12), exportButton],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              exportButton,
            ],
          );
        },
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? context.accentOrOlive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
