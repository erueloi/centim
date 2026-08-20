import 'package:flutter/foundation.dart';

@immutable
class AnnualSubcategoryData {
  final String id;
  final String name;
  final double realSpent;
  final double monthlyAverage;
  final double projectedAnnualTotal;
  final double percentageOfCategory;
  final double percentageOfTotal;
  final double? previousYearAnnualTotal;
  final double? yearOverYearDelta; // p. ex. +0.05 per a +5%

  const AnnualSubcategoryData({
    required this.id,
    required this.name,
    required this.realSpent,
    required this.monthlyAverage,
    required this.projectedAnnualTotal,
    required this.percentageOfCategory,
    required this.percentageOfTotal,
    this.previousYearAnnualTotal,
    this.yearOverYearDelta,
  });
}

@immutable
class AnnualCategoryData {
  final String categoryId;
  final String categoryName;
  final String icon;
  final int? color;
  final double realSpent;
  final double monthlyAverage;
  final double projectedAnnualTotal;
  final double percentageOfTotal;
  final List<AnnualSubcategoryData> subcategories;
  final double? previousYearAnnualTotal;
  final double? yearOverYearDelta; // p. ex. -0.12 per a -12%

  const AnnualCategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    this.color,
    required this.realSpent,
    required this.monthlyAverage,
    required this.projectedAnnualTotal,
    required this.percentageOfTotal,
    required this.subcategories,
    this.previousYearAnnualTotal,
    this.yearOverYearDelta,
  });
}

@immutable
class AnnualReportData {
  final int year;
  final double totalRealIncome;
  final double totalRealRecurringIncome; // Nòmines / isFixed: true
  final double totalRealVariableIncome;  // Bizums, puntuals, etc.
  final double projectedAnnualIncome;    // Recurrent anualitzat + Variable real
  final double projectedAnnualRecurringIncome; // Nòmines anualitzades (12m)
  final double projectedAnnualVariableIncome;  // Variable real acumulat (sense inflar)
  final double monthlyAverageIncome;
  final double monthlyAverageRecurringIncome;
  final double monthlyAverageVariableIncome;

  final double totalRealExpense;
  final double projectedAnnualExpense;
  final double monthlyAverageExpense;
  final int completedCyclesCount;
  final int remainingCyclesCount;
  final int totalCyclesInYear;
  final double debtServiceAnnualTotal;
  final double debtServiceMonthlyAverage;
  final double debtServicePercentage; // sobre la despesa anual total
  final List<AnnualCategoryData> categories;
  final List<AnnualCategoryData> incomeCategories;
  final bool hasPreviousYearData;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;

  // ── BLOC D'ESTALVI I GUARRIOLES (sempre real, no projectat) ──
  final double totalRealSavingsDeposits;
  final int totalRealSavingsDepositsCount;
  final double totalRealSavingsWithdrawals;
  final int totalRealSavingsWithdrawalsCount;

  const AnnualReportData({
    required this.year,
    this.totalRealIncome = 0.0,
    this.totalRealRecurringIncome = 0.0,
    this.totalRealVariableIncome = 0.0,
    this.projectedAnnualIncome = 0.0,
    this.projectedAnnualRecurringIncome = 0.0,
    this.projectedAnnualVariableIncome = 0.0,
    this.monthlyAverageIncome = 0.0,
    this.monthlyAverageRecurringIncome = 0.0,
    this.monthlyAverageVariableIncome = 0.0,
    required this.totalRealExpense,
    required this.projectedAnnualExpense,
    required this.monthlyAverageExpense,
    required this.completedCyclesCount,
    required this.remainingCyclesCount,
    required this.totalCyclesInYear,
    required this.debtServiceAnnualTotal,
    required this.debtServiceMonthlyAverage,
    required this.debtServicePercentage,
    required this.categories,
    this.incomeCategories = const [],
    this.hasPreviousYearData = false,
    this.periodStartDate,
    this.periodEndDate,
    this.totalRealSavingsDeposits = 0.0,
    this.totalRealSavingsDepositsCount = 0,
    this.totalRealSavingsWithdrawals = 0.0,
    this.totalRealSavingsWithdrawalsCount = 0,
  });

  /// Estalvi net del període: Aportacions a guardioles − Retirades de guardioles
  double get netSavings => totalRealSavingsDeposits - totalRealSavingsWithdrawals;

  /// Percentatge d'estalvi retornat al compte: Retirades / Aportacions * 100
  double get savingsReturnedPercentage =>
      totalRealSavingsDeposits > 0 ? (totalRealSavingsWithdrawals / totalRealSavingsDeposits) * 100 : 0.0;

  // ── DIFERENCIALS EN MODE REAL (període auditat) ──
  double get netRealDifference => totalRealIncome - totalRealExpense;
  double get netRealStructuralDifference => totalRealRecurringIncome - totalRealExpense;

  // ── DIFERENCIALS EN MODE PROJECCIÓ (12 mesos) ──
  /// Diferencial Estructural (dominant): Capacitat d'autonomia de la llar (Nòmines - Despesa)
  double get netStructuralDifference => projectedAnnualRecurringIncome - projectedAnnualExpense;

  /// Diferencial de Tresoreria: Entrades totals previstes (Nòmines + Puntuals) - Despesa
  double get netAnnualDifference => projectedAnnualIncome - projectedAnnualExpense;

  double get monthlyNetDifference => monthlyAverageIncome - monthlyAverageExpense;
  double get monthlyNetStructuralDifference => monthlyAverageRecurringIncome - monthlyAverageExpense;
}
