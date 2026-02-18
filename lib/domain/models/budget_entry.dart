import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_entry.freezed.dart';
part 'budget_entry.g.dart';

@freezed
class BudgetEntry with _$BudgetEntry {
  const factory BudgetEntry({
    required String id,
    required String subCategoryId,
    required int year,
    required int month, // 1-12
    required double amount,
  }) = _BudgetEntry;

  factory BudgetEntry.fromJson(Map<String, dynamic> json) =>
      _$BudgetEntryFromJson(json);
}
