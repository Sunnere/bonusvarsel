import 'package:flutter/material.dart';

/// Filters bar tuned for B/C look:
/// - mobile: stack (search -> category -> chips)
/// - desktop/tablet: row (search + category) + chips
class EbFiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String category;
  final List<String> categories;

  final bool onlyCampaigns;
  final bool favFirst;
  final bool sortByRate;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool> onOnlyCampaignsChanged;
  final ValueChanged<bool> onFavFirstChanged;
  final ValueChanged<bool> onSortByRateChanged;

  const EbFiltersBar({
    super.key,
    required this.searchCtrl,
    required this.category,
    required this.categories,
    required this.onlyCampaigns,
    required this.favFirst,
    required this.sortByRate,
    required this.onCategoryChanged,
    required this.onOnlyCampaignsChanged,
    required this.onFavFirstChanged,
    required this.onSortByRateChanged,
  });

  static const double _h = 44;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isNarrow = w < 600;

    final radius = BorderRadius.circular(14);

    InputDecoration deco({
      required String label,
      Widget? prefixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: radius),
      );
    }

    Widget chip({
      required String label,
      required bool selected,
      required ValueChanged<bool> onSelected,
    }) {
      // SAS-ish: subtle outline, selected = warm highlight
      final cs = Theme.of(context).colorScheme;
      final bg = selected ? cs.secondary.withValues(alpha: 0.18) : Colors.transparent;
      final side = BorderSide(
        color: selected ? cs.secondary.withValues(alpha: 0.60) : cs.outline.withValues(alpha: 0.45),
        width: 1,
      );
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: bg,
        selectedColor: bg,
        side: side,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
    }

    final searchField = SizedBox(
      height: _h,
      child: TextField(
        controller: searchCtrl,
        decoration: deco(label: 'Søk butikk', prefixIcon: const Icon(Icons.search)),
      ),
    );

    final categoryField = SizedBox(
      height: _h,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: category,
        items: categories
            .map((c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onCategoryChanged,
        decoration: deco(label: 'Kategori'),
      ),
    );

    final chips = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(
          label: 'Kun kampanjer',
          selected: onlyCampaigns,
          onSelected: onOnlyCampaignsChanged,
        ),
        chip(
          label: 'Favoritter først',
          selected: favFirst,
          onSelected: onFavFirstChanged,
        ),
        chip(
          label: 'Sorter: høy rate',
          selected: sortByRate,
          onSelected: onSortByRateChanged,
        ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          categoryField,
          const SizedBox(height: 10),
          chips,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 10),
            SizedBox(width: 260, child: categoryField),
          ],
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: chips),
      ],
    );
  }
}
