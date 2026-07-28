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
    required double savingsWithdrawalIncome, // Income from savings withdrawals
    required double monthlyExpenses,

    /// Ingressos − despeses del cicle. És una xifra de PRESSUPOST, no de caixa:
    /// no inclou el saldo de partida ni els traspassos, i per tant no quadra
    /// amb els comptes. Es deia `availableToSpend`, i aquell nom feia pensar
    /// que eren diners disponibles al banc.
    required double netOfCycle,
    required double savingsPercentage,
    required double debtPercentage,
    required double livingExpensesPercentage,
    @Default(0.0) double savedThisCycle,
    @Default(0.0) double withdrawnThisCycle,
    @Default({}) Map<String, double> incomesByCategory,
    @Default({}) Map<String, double> expensesByCategory,
  }) = _FinancialSummary;
}
