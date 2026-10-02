import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'personnel_match_header.dart';
import 'personnel_match_badges.dart';
import 'personnel_match_actions.dart';

export 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/match_status_indicator.dart';

class PersonnelMatchCard extends StatelessWidget {
  const PersonnelMatchCard({
    required this.item,
    required this.teamName,
    required this.onSelect,
    required this.onDelete,
    this.onConfirmSuggestion,
    this.onAddNewPerson,
    this.duplicateAssignments,
    this.isFocused = false,
    this.registeredTeamName,
    super.key,
  });

  final ParsedPersonnelItem item;
  final String teamName;
  final String? registeredTeamName;
  final List<String>? duplicateAssignments;
  final bool isFocused;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback? onConfirmSuggestion;
  final VoidCallback? onAddNewPerson;

  @override
  Widget build(BuildContext context) {
    final duplicate = duplicateAssignments?.isNotEmpty == true;
    final problem = duplicate || item.hasWarning || !item.isMatched;

    final accentColor = !item.isMatched
        ? context.rejectedColor
        : (item.hasWarning ? context.warningColor : context.approvedColor);

    final borderColor = isFocused
        ? context.warningColor
        : (problem
            ? accentColor.withValues(alpha: 0.4)
            : context.cardBorderColor);

    final bgColor = isFocused
        ? context.warningBgColor
        : (problem
            ? accentColor.withValues(alpha: 0.035)
            : Theme.of(context).cardColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isFocused ? 2.5 : 1.0),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: context.warningColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol durum renk şeridi (Left Accent Indicator Bar)
              Container(
                width: 5,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PersonnelMatchHeader(
                        item: item,
                        onDelete: onDelete,
                      ),
                      const SizedBox(height: 6),
                      PersonnelMatchBadges(
                        item: item,
                        duplicateAssignments: duplicateAssignments,
                        isFocused: isFocused,
                        onConfirmSuggestion: onConfirmSuggestion,
                      ),
                      const SizedBox(height: 8),
                      PersonnelMatchActions(
                        item: item,
                        teamName: teamName,
                        registeredTeamName: registeredTeamName,
                        onSelect: onSelect,
                        onConfirmSuggestion: onConfirmSuggestion,
                        onAddNewPerson: onAddNewPerson,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
