import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum PersonnelFilter { all, selected, units }

class ActivityFormControls extends StatelessWidget {
  const ActivityFormControls({
    required this.selectedCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.currentFilter,
    required this.onFilterChanged,
    super.key,
  });

  final int selectedCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final PersonnelFilter currentFilter;
  final ValueChanged<PersonnelFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.accentSubtleBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.accentOrOlive,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedCount personel seçildi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      selectedCount == 0
                          ? 'Görevlendirme için personel seçin'
                          : 'Seçilenleri filtreleyerek kontrol edebilirsiniz',
                      style: context.textStyleSecondary.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selectedCount > 0)
                TextButton.icon(
                  onPressed: () => onFilterChanged(PersonnelFilter.selected),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Seçilenler'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Görevlendirilecek Birlikler',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('personnel-search-field'),
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Personel veya birlik ara...',
            prefixIcon: const Icon(Icons.search_rounded, size: 28),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    onPressed: onSearchCleared,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: context.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
                label: 'Sadece Birlikler',
                icon: Icons.apartment_rounded,
                selected: currentFilter == PersonnelFilter.units,
                onTap: () => onFilterChanged(PersonnelFilter.units),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? context.accentOrOlive : context.accentSubtleBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : context.accentOrOlive,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : context.accentOrOlive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
