import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum PersonnelFilter { all, selected, unassigned, unsquadded }

class ActivityFormControls extends StatelessWidget {
  const ActivityFormControls({
    required this.selectedCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.showUnsquaddedFilter,
    super.key,
  });

  final int selectedCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final PersonnelFilter currentFilter;
  final ValueChanged<PersonnelFilter> onFilterChanged;
  final bool showUnsquaddedFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('personnel-search-field'),
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Personel veya birlik ara...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    onPressed: onSearchCleared,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: context.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: context.accentOrOlive, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Hepsi',
                icon: Icons.grid_view_rounded,
                selected: currentFilter == PersonnelFilter.all,
                onTap: () => onFilterChanged(PersonnelFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Seçilenler ($selectedCount)',
                icon: Icons.check_circle_outline_rounded,
                selected: currentFilter == PersonnelFilter.selected,
                onTap: () => onFilterChanged(PersonnelFilter.selected),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Atanmayanlar',
                icon: Icons.radio_button_unchecked_rounded,
                selected: currentFilter == PersonnelFilter.unassigned,
                onTap: () => onFilterChanged(PersonnelFilter.unassigned),
              ),
              if (showUnsquaddedFilter) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Timsiz',
                  icon: Icons.person_off_outlined,
                  selected: currentFilter == PersonnelFilter.unsquadded,
                  onTap: () => onFilterChanged(PersonnelFilter.unsquadded),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.accentOrOlive : context.accentSubtleBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? context.onAccentOrOlive : context.accentOrOlive,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? context.onAccentOrOlive : context.accentOrOlive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
