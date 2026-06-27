import 'package:flutter/material.dart';

class StoreSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;

  const StoreSearchSection({
    super.key,
    required this.controller,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Søk butikker',
            hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
            filled: true,
            fillColor: const Color(0xFF1C1C1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = category == selectedCategory;

              return ChoiceChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => onCategorySelected(category),
              );
            },
          ),
        ),
      ],
    );
  }
}
