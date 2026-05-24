import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/features/transactions/presentation/transaction_confirm_dialog.dart';
import 'package:uangapp/models/transaction.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _textCtrl = TextEditingController();
  final _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechReady = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      showAppSnackBar(context, 'Speech-to-text tidak tersedia');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        showAppSnackBar(context, 'Izin mikrofon diperlukan');
      }
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _textCtrl.text = result.recognizedWords;
          _textCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _textCtrl.text.length),
          );
        });
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: 'id_ID',
        listenMode: stt.ListenMode.confirmation,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 60),
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  void _parseWithAi() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<TransactionBloc>().add(TransactionParseAiRequested(text));
  }

  Future<void> _openManualForm() async {
    if (!mounted) return;
    context.read<TransactionBloc>().add(const TransactionDraftCleared());

    final tx = await showDialog<Transaction>(
      context: context,
      builder: (_) => TransactionConfirmDialog.manual(),
    );
    if (tx != null && mounted) {
      context.read<TransactionBloc>().add(TransactionAddRequested(tx));
      Navigator.pop(context);
    }
  }
  @override
  void dispose() {
    _speech.stop();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listenWhen: (prev, curr) =>
          prev.parsedTransaction != curr.parsedTransaction ||
          prev.isParsingAi != curr.isParsingAi,
      listener: (context, state) async {
        if (state.isParsingAi) return;
        final parsed = state.parsedTransaction;
        if (parsed == null) return;

        final tx = await showDialog<Transaction>(
          context: context,
          builder: (_) => TransactionConfirmDialog(parsed: parsed),
        );
        if (tx != null && context.mounted) {
          context.read<TransactionBloc>().add(TransactionAddRequested(tx));
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tambah Transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Contoh: Barusan beli kopi di Starbucks habis 50 ribu',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : null,
                  ),
                  onPressed: _toggleListening,
                ),
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<TransactionBloc, TransactionState>(
              buildWhen: (p, c) => p.isParsingAi != c.isParsingAi,
              builder: (context, state) {
                return FilledButton.icon(
                  onPressed: state.isParsingAi ? null : _parseWithAi,
                  icon: state.isParsingAi
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(state.isParsingAi ? 'Memproses AI...' : 'Parse dengan AI'),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openManualForm,
              icon: const Icon(Icons.edit),
              label: const Text('Input manual'),
            ),
          ],
        ),
      ),
    );
  }
}
