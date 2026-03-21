import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/slovak_sort.dart';

class CategoryChipFilter extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const CategoryChipFilter({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 SATB poradie speváckych kategórií
    const satbOrder = ["Soprán", "Alt", "Tenor", "Bas"];

    // 🔥 Najprv vyberieme tie, ktoré patria do SATB
    final satbCategories =
        categories.where((c) => satbOrder.contains(c.name)).toList()..sort(
          (a, b) =>
              satbOrder.indexOf(a.name).compareTo(satbOrder.indexOf(b.name)),
        );

    // 🔥 Zvyšné kategórie zoradíme slovensky
    final otherCategories =
        categories.where((c) => !satbOrder.contains(c.name)).toList()
          ..sort((a, b) => slovakCompare(a.name, b.name));

    // 🔥 Kompletný zoznam v správnom poradí
    final sortedCats = [...satbCategories, ...otherCategories];

    return Wrap(
      spacing: 8,
      runSpacing: -8,
      children: [
        ChoiceChip(
          label: const Text("Všetci"),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
        ),

        // 🔥 render sorted categories
        ...sortedCats.map((cat) {
          return ChoiceChip(
            label: Text(cat.name),
            selected: selectedId == cat.id,
            onSelected: (_) => onSelected(cat.id),
          );
        }),
      ],
    );
  }
}
