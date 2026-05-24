import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uangapp/core/utils/date_utils.dart';
import 'package:uangapp/models/parsed_transaction.dart';
import 'package:uangapp/core/utils/month_summary.dart';
import 'package:uangapp/models/transaction.dart';

/// Groq AI via OpenAI-compatible API — **hanya** `GROQ_API_KEY` dari `.env`.
/// Google Sheets/Drive memakai OAuth terpisah di [GoogleAuthService].
class AiService {
  AiService._(this._apiKey, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String _apiKey;
  final http.Client _httpClient;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _modelId = 'llama-3.3-70b-versatile';

  /// Panggil setelah `await dotenv.load()` di [main].
  factory AiService.create({http.Client? httpClient}) {
    final raw = dotenv.env['GROQ_API_KEY'];
    final apiKey = (raw ?? '').trim();
    if (kDebugMode) {
      debugPrint(
        '[AiService] GROQ_API_KEY loaded: length=${apiKey.length}, '
        'configured=${apiKey.isNotEmpty && apiKey != "your_groq_api_key_here"}',
      );
    }
    return AiService._(apiKey, httpClient: httpClient);
  }

  bool get isConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'your_groq_api_key_here';

  static const _parseSystemPrompt = '''
You are a financial transaction parser for an Indonesian personal finance app.
Given natural language (Indonesian or English), extract ONE transaction.

RULES:
- Return ONLY valid JSON, no markdown, no explanation.
- amount: positive number in IDR (e.g. "50 ribu" = 50000, "5 juta" = 5000000).
- type: exactly "Income" or "Expense".
- category: MUST be one of these exact labels:
  Expense: "Makanan & Minuman", "Transportasi", "Belanja", "Tagihan & Utilitas", "Kesehatan", "Hiburan", "Pendidikan", "Rumah & Perawatan", "Hadiah & Donasi", "Lainnya"
  Income: "Gaji", "Freelance", "Investasi", "Hadiah", "Refund", "Lainnya"
- description: short summary in Indonesian.

Example output:
{"amount": 50000, "type": "Expense", "category": "Food & Drinks", "description": "Kopi di Starbucks"}
''';

  void _logError(Object error, StackTrace stackTrace, {String? context}) {
    debugPrint('[AiService] ERROR ${context ?? "chatCompletion"}');
    debugPrint('[AiService] type: ${error.runtimeType}');
    debugPrint('[AiService] message: $error');
    debugPrint('[AiService] stack: $stackTrace');
  }

  static String userFacingMessage(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('rate_limit') ||
        lower.contains('429') ||
        lower.contains('too many requests')) {
      return 'Kuota Groq habis. Coba lagi nanti atau gunakan input manual.';
    }

    if (lower.contains('api key') ||
        lower.contains('invalid api key') ||
        lower.contains('invalid_api_key') ||
        lower.contains('401') ||
        (lower.contains('403') && lower.contains('key'))) {
      return 'API key Groq tidak valid. Pastikan GROQ_API_KEY di .env '
          'adalah key dari console.groq.com (bukan OAuth Sheets).';
    }

    if (lower.contains('model') &&
        (lower.contains('not found') ||
            lower.contains('does not exist') ||
            lower.contains('404'))) {
      return 'Model $_modelId tidak tersedia. Cek model di Groq Console. '
          'Gunakan input manual.';
    }

    return 'AI gagal: $raw';
  }

  Future<String> _chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    required String purpose,
  }) async {
    if (!isConfigured) {
      throw StateError('GROQ_API_KEY belum dikonfigurasi di file .env');
    }

    if (kDebugMode) {
      debugPrint(
        '[AiService] $purpose → model=$_modelId, apiKeyLen=${_apiKey.length}',
      );
    }

    final response = await _httpClient.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _modelId,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.2,
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Groq API ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('Groq tidak mengembalikan choices');
    }

    final message = choices.first as Map<String, dynamic>;
    final content = (message['message'] as Map<String, dynamic>?)?['content']
        as String?;
    final text = content?.trim();
    if (text == null || text.isEmpty) {
      throw const FormatException('Groq tidak mengembalikan teks');
    }
    return text;
  }

  Future<String> _generateText(String prompt, {required String purpose}) async {
    try {
      return await _chatCompletion(
        systemPrompt:
            'You are a helpful Indonesian personal finance assistant. '
            'Follow instructions precisely.',
        userPrompt: prompt,
        purpose: purpose,
      );
    } catch (e, st) {
      _logError(e, st, context: purpose);
      throw StateError(userFacingMessage(e));
    }
  }

  Future<ParsedTransaction> parseTransactionText(String userText) async {
    try {
      final text = await _chatCompletion(
        systemPrompt: _parseSystemPrompt,
        userPrompt: 'User input: "$userText"',
        purpose: 'parseTransaction',
      );
      return ParsedTransaction.fromJson(_extractJson(text));
    } catch (e, st) {
      _logError(e, st, context: 'parseTransaction');
      if (e is StateError) rethrow;
      throw StateError(userFacingMessage(e));
    }
  }

  Future<String> generateMonthlyReport({
    required List<Transaction> monthTransactions,
    required DateTime month,
    MonthFinancialSummary? previousMonthSummary,
  }) async {
    final monthLabel =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    double totalIncome = 0;
    double totalExpense = 0;
    final byCategory = <String, double>{};

    for (final t in monthTransactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    final summary = <String, dynamic>{
      'month': monthLabel,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': totalIncome - totalExpense,
      'expense_by_category': byCategory,
      'transaction_count': monthTransactions.length,
      'transactions': monthTransactions
          .map((t) => {
                'date': formatSheetDate(t.date),
                'amount': t.amount,
                'type': t.typeLabel,
                'category': t.category,
                'description': t.description,
              })
          .toList(),
    };

    if (previousMonthSummary != null) {
      final prev = previousMonthSummary;
      final prevLabel =
          '${prev.month.year}-${prev.month.month.toString().padLeft(2, '0')}';
      summary['previous_month'] = {
        'month': prevLabel,
        'total_income': prev.income,
        'total_expense': prev.expense,
        'balance': prev.balance,
        'expense_by_category': prev.expenseByCategory,
        'transaction_count': prev.transactionCount,
        'expense_change_percent':
            percentChange(totalExpense, prev.expense),
        'income_change_percent': percentChange(totalIncome, prev.income),
      };
    }

    final comparisonNote = previousMonthSummary != null
        ? '\n4. Perbandingan dengan bulan sebelumnya (tren naik/turun pemasukan & pengeluaran, perubahan kategori utama)'
        : '';

    final prompt = '''
Anda adalah asisten keuangan pribadi. Buat laporan bulanan yang ramah dan jelas dalam Bahasa Indonesia
untuk bulan $monthLabel berdasarkan data transaksi berikut (format JSON):

${jsonEncode(summary)}

Sertakan:
1. Ringkasan pemasukan vs pengeluaran
2. Kategori pengeluaran terbesar
3. 2-3 saran praktis menghemat atau meningkatkan tabungan$comparisonNote
Gunakan paragraf singkat dan bullet points. Jangan gunakan markdown code blocks.
''';

    return _generateText(prompt, purpose: 'monthlyReport');
  }

  Map<String, dynamic> _extractJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    }

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('Tidak menemukan JSON dalam respons: $text');
    }

    return jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
  }
}
