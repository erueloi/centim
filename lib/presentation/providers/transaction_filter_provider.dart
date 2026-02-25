import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/transaction_filter.dart';

part 'transaction_filter_provider.g.dart';

@riverpod
class TransactionFilterNotifier extends _$TransactionFilterNotifier {
  @override
  TransactionFilter build() => const TransactionFilter();

  // Single category (used from donut chart navigation)
  void setCategory(String categoryId, String categoryName) {
    state = state.copyWith(
      categoryIds: [categoryId],
      categoryNames: {categoryId: categoryName},
      subCategoryIds: [],
      subCategoryNames: {},
    );
  }

  // Single subcategory (used from watchlist navigation)
  void setSubCategory(
    String categoryId,
    String categoryName,
    String subCategoryId,
    String subCategoryName,
  ) {
    state = state.copyWith(
      categoryIds: [categoryId],
      categoryNames: {categoryId: categoryName},
      subCategoryIds: [subCategoryId],
      subCategoryNames: {subCategoryId: subCategoryName},
    );
  }

  // Toggle category in multi-select
  void toggleCategory(String categoryId, String categoryName) {
    final ids = List<String>.from(state.categoryIds);
    final names = Map<String, String>.from(state.categoryNames);

    if (ids.contains(categoryId)) {
      ids.remove(categoryId);
      names.remove(categoryId);
    } else {
      ids.add(categoryId);
      names[categoryId] = categoryName;
    }

    state = state.copyWith(
      categoryIds: ids,
      categoryNames: names,
    );
  }

  // Toggle subcategory in multi-select
  void toggleSubCategory(String subCategoryId, String subCategoryName) {
    final ids = List<String>.from(state.subCategoryIds);
    final names = Map<String, String>.from(state.subCategoryNames);

    if (ids.contains(subCategoryId)) {
      ids.remove(subCategoryId);
      names.remove(subCategoryId);
    } else {
      ids.add(subCategoryId);
      names[subCategoryId] = subCategoryName;
    }

    state = state.copyWith(
      subCategoryIds: ids,
      subCategoryNames: names,
    );
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query.isEmpty ? null : query);
  }

  void setType(bool? isIncome) {
    state = state.copyWith(isIncome: isIncome);
  }

  void setPayer(String? payer) {
    state = state.copyWith(payer: payer);
  }

  void setAmountRange(double? min, double? max) {
    state = state.copyWith(minAmount: min, maxAmount: max);
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
  }

  void clearCategory() {
    state = state.copyWith(
      categoryIds: [],
      categoryNames: {},
      subCategoryIds: [],
      subCategoryNames: {},
    );
  }

  void clearSubCategory() {
    state = state.copyWith(subCategoryIds: [], subCategoryNames: {});
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: null);
  }

  void clearType() {
    state = state.copyWith(isIncome: null);
  }

  void clearPayer() {
    state = state.copyWith(payer: null);
  }

  void clearAmountRange() {
    state = state.copyWith(minAmount: null, maxAmount: null);
  }

  void clearDateRange() {
    state = state.copyWith(dateFrom: null, dateTo: null);
  }

  void clearAll() {
    state = const TransactionFilter();
  }

  bool get hasActiveFilters =>
      state.categoryIds.isNotEmpty ||
      state.subCategoryIds.isNotEmpty ||
      state.searchQuery != null ||
      state.isIncome != null ||
      state.payer != null ||
      state.minAmount != null ||
      state.maxAmount != null ||
      state.dateFrom != null ||
      state.dateTo != null;
}
