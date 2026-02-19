import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filter.freezed.dart';

@freezed
class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    String? categoryId,
    String? categoryName,
    String? subCategoryId,
    String? subCategoryName,
    String? searchQuery,
    bool? isIncome, // null = all, true = income, false = expense
    String? payer,
    double? minAmount,
    double? maxAmount,
  }) = _TransactionFilter;
}
