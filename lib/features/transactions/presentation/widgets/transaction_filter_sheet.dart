import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/utils/transaction_filters.dart';
import 'package:uangapp/models/transaction.dart';

class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
    required this.onApply,
  });

  final TransactionFilterCriteria initial;
  final List<String> categories;
  final ValueChanged<TransactionFilterCriteria> onApply;

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilterCriteria _criteria;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initial;
    _searchCtrl = TextEditingController(text: _criteria.searchQuery);
    _minCtrl = TextEditingController(
      text: _criteria.minAmount?.toStringAsFixed(0) ?? '',
    );
    _maxCtrl = TextEditingController(
      text: _criteria.maxAmount?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
    widget.onApply(
      _criteria.copyWith(
        searchQuery: _searchCtrl.text,
        minAmount: min,
        maxAmount: max,
        clearMinAmount: _minCtrl.text.trim().isEmpty,
        clearMaxAmount: _maxCtrl.text.trim().isEmpty,
      ),
    );
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _criteria = TransactionFilterCriteria.empty;
      _searchCtrl.clear();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _criteria.dateFrom : _criteria.dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _criteria = isFrom
          ? _criteria.copyWith(dateFrom: picked)
          : _criteria.copyWith(dateTo: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Filter & Urutkan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Cari',
                hintText: 'Deskripsi, kategori, nominal…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Text('Jenis transaksi', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TransactionTypeFilter>(
              segments: const [
                ButtonSegment(
                  value: TransactionTypeFilter.all,
                  label: Text('Semua'),
                ),
                ButtonSegment(
                  value: TransactionTypeFilter.income,
                  label: Text('Masuk'),
                ),
                ButtonSegment(
                  value: TransactionTypeFilter.expense,
                  label: Text('Keluar'),
                ),
              ],
              selected: {_criteria.typeFilter},
              onSelectionChanged: (s) =>
                  setState(() => _criteria = _criteria.copyWith(typeFilter: s.first)),
            ),
            const SizedBox(height: 16),
            DropdownMenu<String?>(
              label: const Text('Kategori'),
              width: double.infinity,
              initialSelection: _criteria.category,
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: null, label: 'Semua kategori'),
                ...widget.categories.map(
                  (c) => DropdownMenuEntry(value: c, label: c),
                ),
              ],
              onSelected: (v) => setState(
                () => _criteria = _criteria.copyWith(
                  category: v,
                  clearCategory: v == null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: true),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _criteria.dateFrom == null
                          ? 'Dari tanggal'
                          : dateFmt.format(_criteria.dateFrom!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: false),
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(
                      _criteria.dateTo == null
                          ? 'Sampai tanggal'
                          : dateFmt.format(_criteria.dateTo!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (_criteria.dateFrom != null || _criteria.dateTo != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(
                    () => _criteria = _criteria.copyWith(
                      clearDateFrom: true,
                      clearDateTo: true,
                    ),
                  ),
                  child: const Text('Hapus rentang tanggal'),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Min (IDR)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Max (IDR)',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownMenu<TransactionSortOption>(
              label: const Text('Urutkan'),
              width: double.infinity,
              initialSelection: _criteria.sort,
              dropdownMenuEntries: TransactionSortOption.values
                  .map(
                    (o) => DropdownMenuEntry(
                      value: o,
                      label: sortOptionLabel(o),
                    ),
                  )
                  .toList(),
              onSelected: (v) {
                if (v != null) {
                  setState(() => _criteria = _criteria.copyWith(sort: v));
                }
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _apply,
              child: const Text('Terapkan filter'),
            ),
          ],
        ),
      ),
    );
  }
}

void showTransactionFilterSheet({
  required BuildContext context,
  required TransactionFilterCriteria initial,
  required List<Transaction> allTransactions,
  required ValueChanged<TransactionFilterCriteria> onApply,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => TransactionFilterSheet(
      initial: initial,
      categories: extractCategories(allTransactions),
      onApply: onApply,
    ),
  );
}
