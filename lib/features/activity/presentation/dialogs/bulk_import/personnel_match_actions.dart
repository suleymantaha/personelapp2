import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class PersonnelMatchActions extends StatelessWidget {
  const PersonnelMatchActions({
    required this.item,
    required this.teamName,
    required this.registeredTeamName,
    required this.onSelect,
    required this.onConfirmSuggestion,
    required this.onAddNewPerson,
    super.key,
  });

  final ParsedPersonnelItem item;
  final String teamName;
  final String? registeredTeamName;
  final VoidCallback onSelect;
  final VoidCallback? onConfirmSuggestion;
  final VoidCallback? onAddNewPerson;

  @override
  Widget build(BuildContext context) {
    return item.isMatched
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.hasWarning && onConfirmSuggestion != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: const Key('bulk-person-confirm-suggestion'),
                    onPressed: onConfirmSuggestion,
                    icon: const Icon(Icons.done_rounded, size: 14),
                    label: const Text(
                      'Onayla',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.approvedColor,
                      foregroundColor:
                          context.onStatusColor(context.approvedColor),
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: context.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final hasRegistered =
                                registeredTeamName?.trim().isNotEmpty == true;
                            final hasList = teamName.trim().isNotEmpty;
                            final isDifferent = hasRegistered &&
                                hasList &&
                                registeredTeamName!.trim().toLowerCase() !=
                                    teamName.trim().toLowerCase();

                            if (isDifferent) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kayitli tim: ${registeredTeamName!.trim()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Liste timi: $teamName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.warningColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final singleTeam = hasRegistered
                                ? 'Kayitli tim: ${registeredTeamName!.trim()}'
                                : (hasList ? 'Liste timi: $teamName' : 'Tim belirtilmedi');

                            return Text(
                              singleTeam,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    key: const Key('bulk-person-select'),
                    onTap: onSelect,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.accentOrOlive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Değiştir',
                            style: TextStyle(
                              color: context.accentOrOlive,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: context.accentOrOlive,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('bulk-person-select-btn'),
                  onPressed: onSelect,
                  icon: const Icon(Icons.search, size: 14),
                  label: const Text(
                    'Personel Seç',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (onAddNewPerson != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('bulk-person-add-new'),
                    onPressed: onAddNewPerson,
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 14,
                    ),
                    label: Text(
                      '+ ${teamName.toLowerCase().contains('tim') ? teamName : '$teamName Timine'} Ekle',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accentOrOlive,
                      foregroundColor: context.onAccentOrOlive,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
  }
}
