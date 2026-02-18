import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_summary.freezed.dart';

@freezed
class FinancialSummary with _$FinancialSummary {
  const factory FinancialSummary({
    required double totalNetWorth,
    required double totalAssets,
    required double totalLiabilities,
    required double equityRatio, // (Assets - Liabilities) / Assets
    required double monthlyIncome,
    required double monthlyExpenses,
    required double availableToSpend,
    required double savingsPercentage,
    required double debtPercentage,
    required double livingExpensesPercentage,
  }) = _FinancialSummary;
}
