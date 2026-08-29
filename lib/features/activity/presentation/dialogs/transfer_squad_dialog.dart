import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

/// Shows a dialog that lets an admin transfer all personnel of [squadId] from
/// [sourceActivity] to another activity on the same date.
///
/// Returns `true` if at least one personnel was moved, `false` / `null` otherwise.
Future<bool?> showTransferSquadDialog(
  BuildContext context, {
  required GunlukFaaliyetTableData sourceActivity,
  required int squadId,
  required String squadName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => TransferSquadDialog(
      sourceActivity: sourceActivity,
      squadId: squadId,
      squadName: squadName,
    ),
  );
}

class TransferSquadDialog extends ConsumerStatefulWidget {
  const TransferSquadDialog({
    required this.sourceActivity,
    required this.squadId,
    required this.squadName,
    super.key,
  });

  final GunlukFaaliyetTableData sourceActivity;
  final int squadId;
  final String squadName;

  @override
  ConsumerState<TransferSquadDialog> createState() =>
      _TransferSquadDialogState();
}

class _TransferSquadDialogState extends ConsumerState<TransferSquadDialog> {
  int? _selectedTargetId;
  bool _isTransferring = false;
  bool _createNewActivity = false;
  final _newActivityNameController = TextEditingController();

  @override
  void dispose() {
    _newActivityNameController.dispose();
    super.dispose();
  }

  Widget _buildNewActivityOption(BuildContext context) {
    if (_createNewActivity) {
      return TextField(
        key: const Key('squad-transfer-new-activity-name'),
        controller: _newActivityNameController,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Yeni faaliyet adı',
          prefixIcon: Icon(Icons.add_card_rounded),
        ),
        onChanged: (_) => setState(() {}),
      );
    }
    return OutlinedButton.icon(
      key: const Key('squad-transfer-create-activity'),
      onPressed: () => setState(() {
        _createNewActivity = true;
        _selectedTargetId = null;
      }),
      icon: const Icon(Icons.add_card_rounded),
      label: const Text('YENİ FAALİYET KARTI OLUŞTUR'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final session = ref.watch(userSessionProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.swap_horiz_rounded,
              color: context.accentOrOlive, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tim Taşı',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.squadName,
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
            // Source info
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
                // Only same-date activities, excluding the source
                final sameDay = activities
                    .where(
                      (a) =>
                          a.tarih == widget.sourceActivity.tarih &&
                          a.id != widget.sourceActivity.id,
                    )
                    .toList();

                final activityList = sameDay.isEmpty
                    ? Padding(
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
                                '${widget.sourceActivity.tarih} tarihinde başka '
                                'faaliyet kartı bulunamadı.',
                                style: TextStyle(
                                  color: context.pendingColor,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: SingleChildScrollView(
                          child: RadioGroup<int>(
                            groupValue: _selectedTargetId,
                            onChanged: (val) => setState(() {
                              _selectedTargetId = val;
                              _createNewActivity = false;
                            }),
                            child: Column(
                              children: sameDay.map((activity) {
                                final isSelected =
                                    _selectedTargetId == activity.id;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.accentOrOlive
                                            .withValues(alpha: 0.10)
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
                                    key: Key('transfer-target-${activity.id}'),
                                    dense: true,
                                    value: activity.id,
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
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    activityList,
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: _buildNewActivityOption(context),
                    ),
                  ],
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
          onPressed:
              _isTransferring ? null : () => Navigator.of(context).pop(false),
          child: const Text('İPTAL'),
        ),
        FilledButton.icon(
          key: const Key('transfer-squad-confirm'),
          icon: _isTransferring
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('TAŞI'),
          onPressed: (_isTransferring ||
                  (_selectedTargetId == null &&
                      (!_createNewActivity ||
                          _newActivityNameController.text.trim().isEmpty)))
              ? null
              : () async {
                  setState(() => _isTransferring = true);
                  final navigator = Navigator.of(context);
                  try {
                    if (session == null) {
                      throw StateError('Oturum bilgisi bulunamadı.');
                    }
                    final repository = ref.read(activityRepositoryProvider);
                    final result = _createNewActivity
                        ? await repository.createActivityAndTransferSquad(
                            sourceActivityId: widget.sourceActivity.id,
                            squadId: widget.squadId,
                            activityName: _newActivityNameController.text,
                            actor: session,
                          )
                        : await repository.transferSquadBetweenActivities(
                            sourceActivityId: widget.sourceActivity.id,
                            targetActivityId: _selectedTargetId!,
                            squadId: widget.squadId,
                            actor: session,
                          );

                    if (!mounted) return;
                    navigator.pop(result.movedCount > 0);

                    if (result.movedCount > 0) {
                      final skippedNote = result.skippedCount > 0
                          ? ' (${result.skippedCount} personel zaten hedef '
                              'faaliyette olduğu için atlandı)'
                          : '';
                      AppNotifications.success(
                        '${widget.squadName}: ${result.movedCount} '
                        'personel başarıyla taşındı.$skippedNote',
                      );
                    } else if (result.skippedCount > 0) {
                      AppNotifications.info(
                        'Tüm personel zaten hedef faaliyette mevcut, '
                        'taşıma yapılmadı.',
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    AppNotifications.error('Taşıma hatası: $e');
                    navigator.pop(false);
                  } finally {
                    if (mounted) setState(() => _isTransferring = false);
                  }
                },
        ),
      ],
    );
  }
}
