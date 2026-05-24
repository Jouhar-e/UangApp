import 'package:uangapp/models/transaction.dart';

enum TransactionTypeFilter { all, income, expense }

enum TransactionSortOption {
  newest,
  oldest,
  amountHigh,
  amountLow,
}

class TransactionFilterCriteria {
  const TransactionFilterCriteria({
    this.searchQuery = '',
    this.typeFilter = TransactionTypeFilter.all,
    this.category,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
    this.sort = TransactionSortOption.newest,
  });

  final String searchQuery;
  final TransactionTypeFilter typeFilter;
  final String? category;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minAmount;
  final double? maxAmount;
  final TransactionSortOption sort;

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      typeFilter != TransactionTypeFilter.all ||
      (category != null && category!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null ||
      minAmount != null ||
      maxAmount != null ||
      sort != TransactionSortOption.newest;

  int get activeFilterCount {
    var n = 0;
    if (searchQuery.trim().isNotEmpty) n++;
    if (typeFilter != TransactionTypeFilter.all) n++;
    if (category != null && category!.isNotEmpty) n++;
    if (dateFrom != null || dateTo != null) n++;
    if (minAmount != null || maxAmount != null) n++;
    if (sort != TransactionSortOption.newest) n++;
    return n;
  }

  TransactionFilterCriteria copyWith({
    String? searchQuery,
    TransactionTypeFilter? typeFilter,
    String? category,
    bool clearCategory = false,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    double? minAmount,
    double? maxAmount,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    TransactionSortOption? sort,
  }) {
    return TransactionFilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      category: clearCategory ? null : (category ?? this.category),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      sort: sort ?? this.sort,
    );
  }

  static const empty = TransactionFilterCriteria();
}

List<Transaction> filterAndSortTransactions(
  List<Transaction> source,
  TransactionFilterCriteria criteria,
) {
  final q = criteria.searchQuery.trim().toLowerCase();

  var list = source.where((t) {
    if (criteria.typeFilter == TransactionTypeFilter.income && !t.isIncome) {
      return false;
    }
    if (criteria.typeFilter == TransactionTypeFilter.expense && t.isIncome) {
      return false;
    }

    if (criteria.category != null &&
        criteria.category!.isNotEmpty &&
        t.category != criteria.category) {
      return false;
    }

    if (criteria.dateFrom != null) {
      final from = DateTime(
        criteria.dateFrom!.year,
        criteria.dateFrom!.month,
        criteria.dateFrom!.day,
      );
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.isBefore(from)) return false;
    }

    if (criteria.dateTo != null) {
      final to = DateTime(
        criteria.dateTo!.year,
        criteria.dateTo!.month,
        criteria.dateTo!.day,
      );
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.isAfter(to)) return false;
    }

    if (criteria.minAmount != null && t.amount < criteria.minAmount!) {
      return false;
    }
    if (criteria.maxAmount != null && t.amount > criteria.maxAmount!) {
      return false;
    }

    if (q.isNotEmpty) {
      final haystack =
          '${t.description} ${t.category} ${t.amount} ${t.typeLabel}'.toLowerCase();
      if (!haystack.contains(q)) return false;
    }

    return true;
  }).toList();

  switch (criteria.sort) {
    case TransactionSortOption.newest:
      list.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
    case TransactionSortOption.oldest:
      list.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
    case TransactionSortOption.amountHigh:
      list.sort((a, b) => b.amount.compareTo(a.amount));
    case TransactionSortOption.amountLow:
      list.sort((a, b) => a.amount.compareTo(b.amount));
  }

  return list;
}

List<String> extractCategories(List<Transaction> transactions) {
  final set = <String>{};
  for (final t in transactions) {
    if (t.category.trim().isNotEmpty) set.add(t.category.trim());
  }
  final list = set.toList()..sort();
  return list;
}

/// Urutan default: perubahan terbaru dulu ([updatedAt]).
List<Transaction> sortTransactionsNewest(List<Transaction> list) {
  final copy = List<Transaction>.from(list);
  copy.sort((a, b) {
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;
    return b.date.compareTo(a.date);
  });
  return copy;
}

String sortOptionLabel(TransactionSortOption option) {
  switch (option) {
    case TransactionSortOption.newest:
      return 'Terbaru';
    case TransactionSortOption.oldest:
      return 'Terlama';
    case TransactionSortOption.amountHigh:
      return 'Nominal tertinggi';
    case TransactionSortOption.amountLow:
      return 'Nominal terendah';
  }
}
