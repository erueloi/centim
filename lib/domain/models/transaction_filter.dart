import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filter.freezed.dart';

@freezed
class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    @Default([]) List<String> categoryIds,
    @Default({}) Map<String, String> categoryNames, // id -> name
    @Default([]) List<String> subCategoryIds,
    @Default({}) Map<String, String> subCategoryNames, // id -> name
    String? searchQuery,
    bool? isIncome, // null = all, true = income, false = expense
    String? payer,
    double? minAmount,
    double? maxAmount,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) = _TransactionFilter;
}
