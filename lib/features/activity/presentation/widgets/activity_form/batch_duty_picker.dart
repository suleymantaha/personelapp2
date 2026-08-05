import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';

Future<String?> showBatchDutyPicker(
  BuildContext context, {
  required String squadName,
  required List<String> duties,
}) {
  final panel = BatchDutyPicker(squadName: squadName, duties: duties);
  if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(heightFactor: 0.82, child: panel),
    );
  }

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dialogContext.cardBorderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: panel,
      ),
    ),
  );
}

class BatchDutyPicker extends StatelessWidget {
  const BatchDutyPicker({
    required this.squadName,
    required this.duties,
    super.key,
  });

  final String squadName;
  final List<String> duties;

  Future<void> _requestClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmationContext) => AlertDialog(
        icon: Icon(
          Icons.restart_alt_rounded,
          color: confirmationContext.rejectedColor,
        ),
        title: const Text('Görevler sıfırlansın mı?'),
        content: Text(
          '$squadName timindeki tüm görev seçimleri kaldırılacak.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmationContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-clear-batch-duty'),
            style: FilledButton.styleFrom(
              backgroundColor: confirmationContext.rejectedColor,
            ),
            onPressed: () => Navigator.pop(confirmationContext, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context, 'CLEAR');
    }
  }

  IconData _iconForDuty(String duty) {
    final normalized = duty.toUpperCase();
    if (normalized.contains('NÖBET')) return Icons.shield_outlined;
    if (normalized.contains('İZİN')) return Icons.beach_access_outlined;
    if (normalized.contains('RAPOR')) return Icons.medical_information_outlined;
    if (normalized.contains('İSTİRAHAT')) return Icons.hotel_outlined;
    if (normalized.contains('SEVK')) return Icons.local_shipping_outlined;
    if (normalized.contains('GÖREVLİ')) return Icons.assignment_ind_outlined;
    if (normalized.contains('DİĞER')) return Icons.more_horiz_rounded;
    return Icons.bolt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.accentSubtleBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.bolt_rounded, color: context.accentOrOlive),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toplu görev ata',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$squadName timindeki tüm personele uygulanır',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: context.cardBorderColor, height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                key: const Key('batch-duty-list'),
                itemCount: duties.length,
                itemBuilder: (context, index) {
                  final duty = duties[index];
                  return ModernActionTile(
                    key: ValueKey('batch-duty-$duty'),
                    option: ModernActionOption(
                      value: duty,
                      title: duty,
                      icon: _iconForDuty(duty),
                    ),
                    onTap: () => Navigator.pop(context, duty),
                  );
                },
              ),
            ),
            Divider(color: context.cardBorderColor, height: 1),
            const SizedBox(height: 8),
            ModernActionTile(
              key: const Key('clear-batch-duty'),
              option: const ModernActionOption(
                value: 'CLEAR',
                title: 'Görevleri sıfırla',
                subtitle: 'Timdeki tüm görev seçimlerini kaldır',
                icon: Icons.restart_alt_rounded,
                isDestructive: true,
              ),
              onTap: () => _requestClear(context),
            ),
          ],
        ),
      ),
    );
  }
}
