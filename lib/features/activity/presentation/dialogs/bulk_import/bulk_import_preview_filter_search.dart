part of 'bulk_import_preview_section.dart';

class _FilterSearchStrip extends StatelessWidget {
  const _FilterSearchStrip({
    required this.selected,
    required this.problemCount,
    required this.allCount,
    required this.readyCount,
    required this.controller,
    required this.onChanged,
    required this.onProblems,
    required this.onAll,
    required this.onReady,
  });

  final _PreviewFilter selected;
  final int problemCount;
  final int allCount;
  final int readyCount;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onProblems;
  final VoidCallback onAll;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final filters = _SegmentedFilters(
      selected: selected,
      problemCount: problemCount,
      allCount: allCount,
      readyCount: readyCount,
      onProblems: onProblems,
      onAll: onAll,
      onReady: onReady,
    );
    final search = TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Personel, tim veya satır ara',
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.cardBorderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(child: filters),
              const SizedBox(width: 10),
              Expanded(child: search),
            ],
          );
        }
        return Column(
          children: [
            filters,
            const SizedBox(height: 8),
            search,
          ],
        );
      },
    );
  }
}

class _SegmentedFilters extends StatelessWidget {
  const _SegmentedFilters({
    required this.selected,
    required this.problemCount,
    required this.allCount,
    required this.readyCount,
    required this.onProblems,
    required this.onAll,
    required this.onReady,
  });

  final _PreviewFilter selected;
  final int problemCount;
  final int allCount;
  final int readyCount;
  final VoidCallback onProblems;
  final VoidCallback onAll;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              label: 'Sorunlar',
              count: problemCount,
              selected: selected == _PreviewFilter.problems,
              onTap: onProblems,
            ),
          ),
          Expanded(
            child: _FilterButton(
              label: 'Tümü',
              count: allCount,
              selected: selected == _PreviewFilter.all,
              onTap: onAll,
            ),
          ),
          Expanded(
            child: _FilterButton(
              label: 'Hazır',
              count: readyCount,
              selected: selected == _PreviewFilter.ready,
              onTap: onReady,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.accentOrOlive : context.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? context.accentOrOlive.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 5),
              _CountBadge(count: count, selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? context.accentOrOlive : context.cardBorderColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: selected
              ? context.customColors.onAccentOrOlive
              : context.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
