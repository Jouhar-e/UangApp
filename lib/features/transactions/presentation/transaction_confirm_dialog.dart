import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uangapp/core/constants/transaction_categories.dart';
import 'package:uangapp/core/utils/amount_parser.dart';
import 'package:uangapp/core/widgets/category_picker_field.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/models/parsed_transaction.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/models/transaction.dart';

/// Konfirmasi hasil AI, input manual, atau ubah transaksi.
class TransactionConfirmDialog extends StatefulWidget {
  const TransactionConfirmDialog({
    super.key,
    required this.parsed,
    this.initial,
    this.manualEntry = false,
    this.isEdit = false,
  });

  factory TransactionConfirmDialog.manual({Key? key}) {
    return TransactionConfirmDialog(
      key: key,
      manualEntry: true,
      parsed: ParsedTransaction.emptyForm,
    );
  }

  factory TransactionConfirmDialog.edit({
    Key? key,
    required Transaction initial,
  }) {
    return TransactionConfirmDialog(
      key: key,
      isEdit: true,
      initial: initial,
      parsed: ParsedTransaction(
        amount: initial.amount,
        type: initial.type,
        category: initial.category,
        description: initial.description,
      ),
    );
  }

  final ParsedTransaction parsed;
  final Transaction? initial;
  final bool manualEntry;
  final bool isEdit;

  @override
  State<TransactionConfirmDialog> createState() =>
      _TransactionConfirmDialogState();
}

class _TransactionConfirmDialogState extends State<TransactionConfirmDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;
  late String _category;
  late TransactionType _type;
  late DateTime _dateTime;

  @override
  void initState() {
    super.initState();
    final p = widget.parsed;
    final i = widget.initial;
    if (widget.manualEntry) {
      _amountCtrl = TextEditingController();
      _descriptionCtrl = TextEditingController();
      _type = TransactionType.expense;
      _category = TransactionCategories.expense.first;
      _dateTime = DateTime.now();
    } else {
      _amountCtrl = TextEditingController(
        text: (i?.amount ?? p.amount).toStringAsFixed(0),
      );
      _category = TransactionCategories.normalize(
        i?.category ?? p.category,
        i?.type ?? p.type,
      );
      _descriptionCtrl =
          TextEditingController(text: i?.description ?? p.description);
      _type = i?.type ?? p.type;
      _dateTime = i?.createdAt ?? i?.date ?? DateTime.now();
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Transaction? _buildTransaction() {
    final amount = parseManualAmountInput(_amountCtrl.text);
    if (amount == null || amount <= 0) return null;

    final dt = _dateTime;
    final base = widget.initial;
    if (widget.isEdit && base != null) {
      return base.copyWith(
        date: DateTime(dt.year, dt.month, dt.day),
        amount: amount,
        category: _category,
        description: _descriptionCtrl.text.trim(),
        type: _type,
        createdAt: dt,
        updatedAt: DateTime.now(),
      );
    }

    return Transaction(
      id: '',
      date: DateTime(dt.year, dt.month, dt.day),
      amount: amount,
      category: _category,
      description: _descriptionCtrl.text.trim(),
      type: _type,
      createdAt: dt,
      updatedAt: dt,
    );
  }

  void _submit() {
    final tx = _buildTransaction();
    if (tx == null) {
      showAppSnackBar(
        context,
        'Isi jumlah (IDR) dan kategori. Contoh: 50000 atau 50.000',
      );
      return;
    }
    Navigator.of(context).pop(tx);
  }

  String get _title {
    if (widget.isEdit) return 'Ubah transaksi';
    if (widget.manualEntry) return 'Input manual';
    return 'Konfirmasi transaksi';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.remove),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.add),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  _category = TransactionCategories.forType(_type).first;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah (IDR)',
                hintText: '50000',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            CategoryPickerField(
              type: _type,
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal & waktu'),
              subtitle: Text(
                DateFormat('d MMM yyyy · HH:mm', 'id_ID').format(_dateTime),
              ),
              trailing: const Icon(Icons.schedule),
              onTap: _pickDateTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
