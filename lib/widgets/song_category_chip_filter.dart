import 'package:flutter/material.dart';
import '../models/song_category.dart';

// 🔥 centrálne triedenie
import '../utils/slovak_sort.dart';

class SongCategoryChipFilter extends StatelessWidget {
  final List<SongCategory> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const SongCategoryChipFilter({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 Default kategória ako prvá
    final def = categories.firstWhere((c) => c.isDefault == true);
    final rest = categories.where((c) => c.isDefault == false).toList()
      ..sort((a, b) => slovakCompare(a.name, b.name));

    final sortedCats = [def, ...rest]; // 🔥 konečný zoznam

    return Wrap(
      spacing: 8,
      runSpacing: -8,
      children: [
        // ALL chip
        ChoiceChip(
          label: const Text("Všetky"),
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
        ),

        // CATEGORY CHIPS
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
