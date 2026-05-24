import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/models/pending_sync_operation.dart';
import 'package:uangapp/models/transaction.dart';

class SqliteService {
  SqliteService._();
  static final SqliteService instance = SqliteService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'uangapp.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            date TEXT,
            amount REAL,
            category TEXT,
            description TEXT,
            type TEXT,
            created_at TEXT,
            updated_at TEXT,
            is_deleted INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_transactions_is_deleted ON transactions(is_deleted)
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id TEXT PRIMARY KEY,
            op_type TEXT,
            enqueued_at TEXT
          )
        ''');

        // Panggil migrasi data dari SharedPreferences setelah tabel terbentuk
        await _migrateFromSharedPreferences(db);
      },
    );
  }

  Future<void> _migrateFromSharedPreferences(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Migrasi Cache Transaksi
      final cacheRaw = prefs.getStringList(AppConstants.cacheTransactionsKey);
      if (cacheRaw != null && cacheRaw.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[SqliteService] Melakukan migrasi ${cacheRaw.length} transaksi dari SharedPreferences...');
        }
        final batch = db.batch();
        for (final s in cacheRaw) {
          try {
            final tx = Transaction.fromJson(jsonDecode(s) as Map<String, dynamic>);
            batch.insert(
              'transactions',
              {
                'id': tx.id,
                'date': tx.toJson()['date'],
                'amount': tx.amount,
                'category': tx.category,
                'description': tx.description,
                'type': tx.toJson()['type'],
                'created_at': tx.toJson()['created_at'],
                'updated_at': tx.toJson()['updated_at'],
                'is_deleted': tx.isDeleted ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (_) {}
        }
        await batch.commit(noResult: true);
        await prefs.remove(AppConstants.cacheTransactionsKey);
      }

      // 2. Migrasi Sync Queue
      final queueRaw = prefs.getStringList(AppConstants.pendingSyncQueueKey);
      if (queueRaw != null && queueRaw.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[SqliteService] Melakukan migrasi ${queueRaw.length} antrean sinkronisasi dari SharedPreferences...');
        }
        final batch = db.batch();
        for (final s in queueRaw) {
          try {
            final op = PendingSyncOperation.fromJson(jsonDecode(s) as Map<String, dynamic>);
            // Simpan transaksi terkait jika belum ada
            batch.insert(
              'transactions',
              {
                'id': op.transaction.id,
                'date': op.transaction.toJson()['date'],
                'amount': op.transaction.amount,
                'category': op.transaction.category,
                'description': op.transaction.description,
                'type': op.transaction.toJson()['type'],
                'created_at': op.transaction.toJson()['created_at'],
                'updated_at': op.transaction.toJson()['updated_at'],
                'is_deleted': op.transaction.isDeleted ? 1 : 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Simpan ke antrean
            batch.insert(
              'sync_queue',
              {
                'id': op.transaction.id,
                'op_type': op.type.name,
                'enqueued_at': op.enqueuedAt.toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (_) {}
        }
        await batch.commit(noResult: true);
        await prefs.remove(AppConstants.pendingSyncQueueKey);
      }
    } catch (e) {
      debugPrint('[SqliteService] ERROR migrasi data: $e');
    }
  }

  // --- Operasi Transaksi ---

  Future<List<Transaction>> loadTransactions({bool includeDeleted = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (includeDeleted) {
      maps = await db.query('transactions', orderBy: 'updated_at DESC');
    } else {
      maps = await db.query(
        'transactions',
        where: 'is_deleted = 0',
        orderBy: 'updated_at DESC',
      );
    }

    return maps.map((m) {
      return Transaction(
        id: m['id'] as String,
        date: parseSheetDate(m['date'] as String?) ?? DateTime.now(),
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] as String,
        description: m['description'] as String,
        type: Transaction.parseType(m['type'] as String?),
        createdAt: parseSheetDateTime(m['created_at'] as String?) ?? DateTime.now(),
        updatedAt: parseSheetDateTime(m['updated_at'] as String?) ?? DateTime.now(),
        isDeleted: (m['is_deleted'] as int) == 1,
      );
    }).toList();
  }

  Future<void> saveTransaction(Transaction tx) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': tx.id,
        'date': tx.toJson()['date'],
        'amount': tx.amount,
        'category': tx.category,
        'description': tx.description,
        'type': tx.toJson()['type'],
        'created_at': tx.toJson()['created_at'],
        'updated_at': tx.toJson()['updated_at'],
        'is_deleted': tx.isDeleted ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final db = await database;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        {
          'id': tx.id,
          'date': tx.toJson()['date'],
          'amount': tx.amount,
          'category': tx.category,
          'description': tx.description,
          'type': tx.toJson()['type'],
          'created_at': tx.toJson()['created_at'],
          'updated_at': tx.toJson()['updated_at'],
          'is_deleted': tx.isDeleted ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteTransactionLocally(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Operasi Sync Queue ---

  Future<List<PendingSyncOperation>> loadPendingSyncOperations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sync_queue', orderBy: 'enqueued_at ASC');
    final List<PendingSyncOperation> ops = [];

    for (final m in maps) {
      final id = m['id'] as String;
      final opTypeName = m['op_type'] as String;
      final enqueuedAtRaw = m['enqueued_at'] as String;

      final txList = await db.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
      if (txList.isNotEmpty) {
        final txMap = txList.first;
        final tx = Transaction(
          id: txMap['id'] as String,
          date: parseSheetDate(txMap['date'] as String?) ?? DateTime.now(),
          amount: (txMap['amount'] as num).toDouble(),
          category: txMap['category'] as String,
          description: txMap['description'] as String,
          type: Transaction.parseType(txMap['type'] as String?),
          createdAt: parseSheetDateTime(txMap['created_at'] as String?) ?? DateTime.now(),
          updatedAt: parseSheetDateTime(txMap['updated_at'] as String?) ?? DateTime.now(),
          isDeleted: (txMap['is_deleted'] as int) == 1,
        );

        ops.add(
          PendingSyncOperation(
            type: SyncOpType.values.byName(opTypeName),
            transaction: tx,
            enqueuedAt: DateTime.tryParse(enqueuedAtRaw) ?? DateTime.now(),
          ),
        );
      }
    }
    return ops;
  }

  Future<void> enqueueSyncOperation(PendingSyncOperation op) async {
    final db = await database;
    // Simpan transaksi pendukung terlebih dahulu
    await saveTransaction(op.transaction);

    await db.insert(
      'sync_queue',
      {
        'id': op.transaction.id,
        'op_type': op.type.name,
        'enqueued_at': op.enqueuedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSyncOperation(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }
}

// Helpers parsing manual untuk SQLite model mapping
DateTime? parseSheetDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  try {
    if (trimmed.length >= 10) {
      return DateTime.parse(trimmed.substring(0, 10));
    }
    return DateTime.parse(trimmed);
  } catch (_) {
    return null;
  }
}

DateTime? parseSheetDateTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    return DateTime.parse(value.trim());
  } catch (_) {
    return parseSheetDate(value);
  }
}
