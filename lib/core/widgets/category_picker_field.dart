import 'package:flutter/material.dart';
import 'package:uangapp/core/constants/transaction_categories.dart';
import 'package:uangapp/models/transaction.dart';

class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  final TransactionType type;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = TransactionCategories.forType(type);
    final selected = options.contains(value)
        ? value
        : TransactionCategories.normalize(value, type);

    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Kategori',
      ),
      items: options
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
