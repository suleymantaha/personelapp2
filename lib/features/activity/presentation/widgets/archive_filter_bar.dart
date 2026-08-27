import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';

class ArchiveFilterBar extends StatelessWidget {
  const ArchiveFilterBar({
    required this.isAdmin,
    required this.squads,
    required this.selectedSquadId,
    required this.onSquadSelected,
    super.key,
  });

  final bool isAdmin;
  final List<TimTableData> squads;
  final int? selectedSquadId;
  final ValueChanged<int?> onSquadSelected;

  @override
  Widget build(BuildContext context) {
    if (!isAdmin || squads.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedSquads = MilitaryStructureHelper.sortSquads(
      squads,
      (squad) => squad.timAdi,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Tüm Timler'),
            avatar: selectedSquadId == null
                ? const Icon(Icons.check_circle, size: 20)
                : null,
            selected: selectedSquadId == null,
            selectedColor: context.accentOrOlive,
            backgroundColor: context.colorScheme.surface,
            side: BorderSide(color: context.cardBorderColor),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                backgroundColor: context.colorScheme.surface,
                side: BorderSide(color: context.cardBorderColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
    );
  }
}
