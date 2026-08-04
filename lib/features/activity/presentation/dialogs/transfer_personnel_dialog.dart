import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

/// Açılır diyalog: [assignment] sahibi personeli, [sourceActivity] ile
/// aynı tarihteki başka bir faaliyet kartına taşır.
///
/// `true` → başarılı taşıma, `false/null` → iptal veya başarısız.
Future<bool?> showTransferPersonnelDialog(
  BuildContext context, {
  required GunlukFaaliyetTableData sourceActivity,
  required FaaliyetPersonelAtamaTableData assignment,
  required String personnelDisplayName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => TransferPersonnelDialog(
      sourceActivity: sourceActivity,
      assignment: assignment,
      personnelDisplayName: personnelDisplayName,
    ),
  );
}

class TransferPersonnelDialog extends ConsumerStatefulWidget {
  const TransferPersonnelDialog({
    required this.sourceActivity,
    required this.assignment,
    required this.personnelDisplayName,
    super.key,
  });

  final GunlukFaaliyetTableData sourceActivity;
  final FaaliyetPersonelAtamaTableData assignment;
  final String personnelDisplayName;

  @override
  ConsumerState<TransferPersonnelDialog> createState() =>
      _TransferPersonnelDialogState();
}

class _TransferPersonnelDialogState
    extends ConsumerState<TransferPersonnelDialog> {
  int? _selectedTargetId;
  bool _isTransferring = false;

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final session = ref.watch(userSessionProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.person_pin_rounded, color: context.accentOrOlive, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personel Taşı',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.personnelDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kaynak bilgisi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 14,
                    color: context.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kaynak: ${widget.sourceActivity.faaliyetAdi}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hedef Faaliyet Kartını Seçin:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            activitiesAsync.when(
              data: (activities) {
                final sameDay = activities
                    .where(
                      (a) =>
                          a.tarih == widget.sourceActivity.tarih &&
                          a.id != widget.sourceActivity.id,
                    )
                    .toList();

                if (sameDay.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.pendingColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.sourceActivity.tarih} tarihinde '
                            'başka faaliyet kartı bulunamadı.',
                            style: TextStyle(
                              color: context.pendingColor,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Column(
                      children: sameDay.map((activity) {
                        final isSelected = _selectedTargetId == activity.id;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.accentOrOlive.withValues(alpha: 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? context.accentOrOlive
                                  : context.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          child: RadioListTile<int>(
                            key: Key('personnel-transfer-target-${activity.id}'),
                            dense: true,
                            value: activity.id,
                            groupValue: _selectedTargetId,
                            activeColor: context.accentOrOlive,
                            title: Text(
                              activity.faaliyetAdi,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onChanged: (val) =>
                                setState(() => _selectedTargetId = val),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text(
                'Hata: $err',
                style: TextStyle(color: context.rejectedColor),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTransferring
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('İPTAL'),
        ),
        FilledButton.icon(
          key: const Key('personnel-transfer-confirm'),
          icon: _isTransferring
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.person_pin_rounded, size: 18),
          label: const Text('TAŞI'),
          onPressed: (_selectedTargetId == null || _isTransferring)
              ? null
              : () async {
                  setState(() => _isTransferring = true);
                  try {
                    final result = await ref
                        .read(activityRepositoryProvider)
                        .transferPersonnelBetweenActivities(
                          assignmentId: widget.assignment.id,
                          targetActivityId: _selectedTargetId!,
                          actor: session!,
                        );

                    if (!mounted) return;
                    Navigator.of(context).pop(result.moved);

                    if (result.moved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.personnelDisplayName} başarıyla taşındı.',
                          ),
                          backgroundColor: context.approvedColor,
                        ),
                      );
                    } else if (!result.moved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.reason ?? 'Taşıma yapılamadı.'),
                          backgroundColor: context.pendingColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Taşıma hatası: $e'),
                        backgroundColor: context.rejectedColor,
                      ),
                    );
                    Navigator.of(context).pop(false);
                  } finally {
                    if (mounted) setState(() => _isTransferring = false);
                  }
                },
        ),
      ],
    );
  }
}
