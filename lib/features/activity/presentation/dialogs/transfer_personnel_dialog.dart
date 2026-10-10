import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';

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
        key: const Key('personnel-transfer-new-activity-name'),
        controller: _newActivityNameController,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: context.l10n.transferPersonnelNewActivityLabel,
          prefixIcon: Icon(Icons.add_card_rounded),
        ),
        onChanged: (_) => setState(() {}),
      );
    }
    return OutlinedButton.icon(
      key: const Key('personnel-transfer-create-activity'),
      onPressed: () => setState(() {
        _createNewActivity = true;
        _selectedTargetId = null;
      }),
      icon: const Icon(Icons.add_card_rounded),
      label: Text(context.l10n.transferPersonnelCreateNewOption),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final session = ref.watch(userSessionProvider);
    final l10n = context.l10n;

    return PopScope(
      canPop: !_isTransferring,
      child: AbsorbPointer(
        absorbing: _isTransferring,
        child: AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person_pin_rounded,
                color: context.accentOrOlive,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transferPersonnelTitle,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                          context.l10n.transferPersonnelSourceLabel(widget.sourceActivity.faaliyetAdi),
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
                  context.l10n.transferPersonnelSelectTarget,
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
                                    context.l10n.transferActivitiesNoOtherActivities(
                                      widget.sourceActivity.tarih,
                                    ),
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
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? context.accentOrOlive.withValues(
                                                alpha: 0.10,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? context.accentOrOlive
                                              : context
                                                    .colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: RadioListTile<int>(
                                          key: Key(
                                            'personnel-transfer-target-${activity.id}',
                                          ),
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
                    context.l10n.commonErrorWithDetails(err.toString()),
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
              child: Text(context.l10n.commonCancel.toUpperCase()),
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
              label: Text(context.l10n.transferPersonnelButton),
              onPressed:
                  (_isTransferring ||
                      (_selectedTargetId == null &&
                          (!_createNewActivity ||
                              _newActivityNameController.text.trim().isEmpty)))
                  ? null
                  : () async {
                      setState(() => _isTransferring = true);
                      final navigator = Navigator.of(context);
                      final l10n = context.l10n;
                      try {
                        if (session == null) {
                          throw StateError(l10n.authSessionFailed);
                        }
                        final repository = ref.read(activityRepositoryProvider);
                        final result = _createNewActivity
                            ? await repository
                                  .createActivityAndTransferPersonnel(
                                    assignmentId: widget.assignment.id,
                                    activityName:
                                        _newActivityNameController.text,
                                    actor: session,
                                  )
                            : await repository
                                  .transferPersonnelBetweenActivities(
                                    assignmentId: widget.assignment.id,
                                    targetActivityId: _selectedTargetId!,
                                    actor: session,
                                  );

                        if (!mounted) return;
                        navigator.pop(result.moved);

                        if (result.moved) {
                          AppNotifications.success(
                            l10n.transferPersonnelSuccess(widget.personnelDisplayName),
                          );
                        } else {
                          AppNotifications.warning(
                            result.reason ?? l10n.transferPersonnelFailed,
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        AppNotifications.error(l10n.transferPersonnelError('$e'));
                        navigator.pop(false);
                      } finally {
                        if (mounted) setState(() => _isTransferring = false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
