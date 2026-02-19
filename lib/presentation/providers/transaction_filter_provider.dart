import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/transaction_filter.dart';

part 'transaction_filter_provider.g.dart';

@riverpod
class TransactionFilterNotifier extends _$TransactionFilterNotifier {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setCategory(String categoryId, String categoryName) {
    state = state.copyWith(
      categoryId: categoryId,
      categoryName: categoryName,
      subCategoryId: null,
      subCategoryName: null,
    );
  }

  void setSubCategory(
    String categoryId,
    String categoryName,
    String subCategoryId,
    String subCategoryName,
  ) {
    state = state.copyWith(
      categoryId: categoryId,
      categoryName: categoryName,
      subCategoryId: subCategoryId,
      subCategoryName: subCategoryName,
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

  void clearCategory() {
    state = state.copyWith(
      categoryId: null,
      categoryName: null,
      subCategoryId: null,
      subCategoryName: null,
    );
  }

  void clearSubCategory() {
    state = state.copyWith(subCategoryId: null, subCategoryName: null);
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

  void clearAll() {
    state = const TransactionFilter();
  }

  bool get hasActiveFilters =>
      state.categoryId != null ||
      state.subCategoryId != null ||
      state.searchQuery != null ||
      state.isIncome != null ||
      state.payer != null ||
      state.minAmount != null ||
      state.maxAmount != null;
}
