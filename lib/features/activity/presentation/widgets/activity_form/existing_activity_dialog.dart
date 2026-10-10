import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

enum ExistingActivityAction { merge, createNew }

class ExistingActivityChoice {
  const ExistingActivityChoice({
    required this.action,
    this.activityId,
    this.updateDifferentAssignments = false,
  });

  final ExistingActivityAction action;
  final int? activityId;
  final bool updateDifferentAssignments;
}

class ExistingActivityDialog extends StatefulWidget {
  const ExistingActivityDialog({
    required this.matches,
    super.key,
  });

  final List<ExistingActivityMatch> matches;

  static Future<ExistingActivityChoice?> show(
    BuildContext context,
    List<ExistingActivityMatch> matches,
  ) {
    return showDialog<ExistingActivityChoice>(
      context: context,
      builder: (context) => ExistingActivityDialog(matches: matches),
    );
  }

  @override
  State<ExistingActivityDialog> createState() => _ExistingActivityDialogState();
}

class _ExistingActivityDialogState extends State<ExistingActivityDialog> {
  late int _selectedId;
  bool _updateDifferent = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.matches.first.activity.id;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.matches.firstWhere(
      (match) => match.activity.id == _selectedId,
    );

    return AlertDialog(
      title: Text(context.l10n.activityExistingDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.activityExistingDialogFoundDate(
                selected.activity.tarih,
                selected.activity.faaliyetAdi,
                widget.matches.length,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.matches.length > 1)
              DropdownButtonFormField<int>(
                menuMaxHeight: modernDropdownMenuMaxHeight(context),
                borderRadius: modernDropdownBorderRadius,
                dropdownColor: modernDropdownColor(context),
                initialValue: _selectedId,
                decoration: InputDecoration(
                  labelText: context.l10n.activityExistingDialogToUpdate,
                  border: const OutlineInputBorder(),
                ),
                items: widget.matches
                    .map(
                      (match) => DropdownMenuItem(
                        value: match.activity.id,
                        child: Text(
                          '#${match.activity.id} • '
                          '${match.activity.faaliyetAdi}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedId = value;
                      _updateDifferent = false;
                    });
                  }
                },
              ),
            if (widget.matches.length > 1) const SizedBox(height: 12),
            Text(
              context.l10n.activityExistingDialogNewPersonnelToAdd(
                selected.newPersonnelCount,
              ),
            ),
            Text(
              context.l10n.activityExistingDialogAlreadyRegistered(
                selected.unchangedPersonnelCount,
              ),
            ),
            Text(
              context.l10n.activityExistingDialogDifferentPersonnelCountNote(
                selected.differentPersonnelCount,
              ),
            ),
            if (selected.differentPersonnelCount > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _updateDifferent,
                title: Text(
                  context.l10n.activityExistingDialogUpdateDifferent,
                ),
                subtitle: Text(
                  context.l10n.activityExistingDialogKeepIfUnselected,
                ),
                onChanged: (value) => setState(
                  () => _updateDifferent = value ?? false,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel.toUpperCase()),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(
            context,
            const ExistingActivityChoice(
              action: ExistingActivityAction.createNew,
            ),
          ),
          child: Text(context.l10n.activityExistingDialogCreateNew),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ExistingActivityChoice(
              action: ExistingActivityAction.merge,
              activityId: _selectedId,
              updateDifferentAssignments: _updateDifferent,
            ),
          ),
          child: Text(context.l10n.activityExistingDialogAddToExisting),
        ),
      ],
    );
  }
}
