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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Görevlendirilecek Birlikler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            if (selectedCount > 0)
              Container(
                key: const Key('selected-personnel-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.accentSubtleBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedCount seçili',
                  style: TextStyle(
                    color: context.accentOrOlive,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('personnel-search-field'),
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Personel veya birlik ara',
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(context, 'Tümü', PersonnelFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Seçili', PersonnelFilter.selected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Birlik', PersonnelFilter.units),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    PersonnelFilter filter,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: currentFilter == filter,
      showCheckmark: false,
      onSelected: (_) => onFilterChanged(filter),
    );
  }
}
