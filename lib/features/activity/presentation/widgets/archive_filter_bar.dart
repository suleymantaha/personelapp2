import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';

class ArchiveFilterBar extends StatelessWidget {
  const ArchiveFilterBar({
    required this.isAdmin,
    required this.squads,
    required this.selectedSquadId,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSquadSelected,
    super.key,
  });

  final bool isAdmin;
  final List<TimTableData> squads;
  final int? selectedSquadId;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onSquadSelected;

  @override
  Widget build(BuildContext context) {
    final sortedSquads = MilitaryStructureHelper.sortSquads(
      squads,
      (squad) => squad.timAdi,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Faaliyet veya tarih ara…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: context.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cardBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cardBorderColor),
                    ),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
            ],
          ),
        ),
        if (isAdmin && squads.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tüm Timler'),
                  selected: selectedSquadId == null,
                  selectedColor: context.accentOrOlive,
                  labelStyle: TextStyle(
                    color: selectedSquadId == null
                        ? Colors.white
                        : context.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => onSquadSelected(null),
                ),
                const SizedBox(width: 8),
                ...sortedSquads.map((sq) {
                  final isSel = selectedSquadId == sq.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sq.timAdi),
                      selected: isSel,
                      selectedColor: context.accentOrOlive,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => onSquadSelected(sq.id),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
