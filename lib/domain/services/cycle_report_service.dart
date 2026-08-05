import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/billing_cycle.dart';
import '../models/budget_entry.dart';
import '../models/category.dart';
import '../models/cycle_report.dart';
import '../models/transaction.dart';
import 'ledger_service.dart';

/// Versió de l'estructura i la semàntica pròpies de l'informe.
/// És independent de [kLedgerSchemaVersion]: el prompt o les mètriques del
/// report poden canviar encara que la classificació del ledger no ho faci.
const int kCycleReportSchemaVersion = 1;

bool isCycleReportOutdated({
  required CycleReport report,
  required BillingCycle cycle,
  required String currentFingerprint,
}) {
  bool sameDay(DateTime? left, DateTime right) =>
      left != null && _day(left) == _day(right);
  return report.reportSchemaVersion != kCycleReportSchemaVersion ||
      report.ledgerSchemaVersion != kLedgerSchemaVersion ||
      report.sourceFingerprint.isEmpty ||
      report.sourceFingerprint != currentFingerprint ||
      !sameDay(report.generatedForStartDate, cycle.startDate) ||
      !sameDay(report.generatedForEndDate, cycle.endDate);
}

String _day(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

/// Empremta determinista de totes les entrades que poden alterar un report.
/// No intenta explicar el canvi: només permet saber que cal regenerar-lo.
String buildCycleReportSourceFingerprint({
  required BillingCycle cycle,
  required List<Transaction> transactions,
  required List<Category> categories,
  required List<BudgetEntry> budgetEntries,
}) {
  final cycleTransactions = transactions
      .where((transaction) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        final start = DateTime(
          cycle.startDate.year,
          cycle.startDate.month,
          cycle.startDate.day,
        );
        final end = DateTime(
          cycle.endDate.year,
          cycle.endDate.month,
          cycle.endDate.day,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      })
      .map(
        (transaction) => <String, Object?>{
          'id': transaction.id,
          'date': transaction.date.toUtc().toIso8601String(),
          'amount': transaction.amount,
          'concept': transaction.concept,
          'categoryId': transaction.categoryId,
          'subCategoryId': transaction.subCategoryId,
          'isIncome': transaction.isIncome,
          'savingsGoalId': transaction.savingsGoalId,
        },
      )
      .toList()
    ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));

  final categoryData = categories
      .map(
        (category) => <String, Object?>{
          'id': category.id,
          'name': category.name,
          'type': category.type.name,
          'archived': category.archived,
          'subcategories': (category.subcategories
              .map(
                (subcategory) => <String, Object?>{
                  'id': subcategory.id,
                  'name': subcategory.name,
                  'monthlyBudget': subcategory.monthlyBudget,
                  'archived': subcategory.archived,
                  'linkedSavingsGoalId': subcategory.linkedSavingsGoalId,
                },
              )
              .toList()
            ..sort(
              (a, b) => (a['id'] as String).compareTo(b['id'] as String),
            )),
        },
      )
      .toList()
    ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  final budgetData = budgetEntries
      .map(
        (entry) => <String, Object?>{
          'id': entry.id,
          'subCategoryId': entry.subCategoryId,
          'year': entry.year,
          'month': entry.month,
          'amount': entry.amount,
        },
      )
      .toList()
    ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));

  final canonicalJson = jsonEncode({
    'cycle': {
      'id': cycle.id,
      'startDate': _day(cycle.startDate),
      'endDate': _day(cycle.endDate),
    },
    'transactions': cycleTransactions,
    'categories': categoryData,
    'budgetEntries': budgetData,
  });
  return sha256.convert(utf8.encode(canonicalJson)).toString();
}

int countCanonicalZeroExpenseDays({
  required BillingCycle cycle,
  required List<Transaction> cycleTransactions,
  required LedgerLookups lookups,
}) {
  final dailyExpense = <String, double>{};
  for (final transaction in cycleTransactions) {
    final classification = classifyTransaction(transaction, lookups);
    if (classification.bucket != LedgerBucket.expense) continue;
    final key = _day(transaction.date);
    dailyExpense[key] = (dailyExpense[key] ?? 0) + classification.delta;
  }
  final expenseDays = dailyExpense.values.where((amount) => amount > 0).length;
  final totalDays = DateTime(
        cycle.endDate.year,
        cycle.endDate.month,
        cycle.endDate.day,
      )
          .difference(
            DateTime(
              cycle.startDate.year,
              cycle.startDate.month,
              cycle.startDate.day,
            ),
          )
          .inDays +
      1;
  return (totalDays - expenseDays).clamp(0, totalDays);
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-zà-öø-ÿ0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Aproximació temporal acordada fins que existeixi un marcador estructurat.
/// No codifica persones: només etiquetes genèriques de Bizum/transferència.
bool isPersonalTransferIncome(
  Transaction transaction, {
  String currentCategoryName = '',
  String currentSubcategoryName = '',
}) {
  final haystack = _normalize([
    transaction.concept,
    transaction.categoryName,
    transaction.subCategoryName,
    currentCategoryName,
    currentSubcategoryName,
  ].join(' '));
  const markers = [
    'bizum',
    'transferencia particular',
    'transferència particular',
    'transferencies particulars',
    'transferències particulars',
    'transferencia de particular',
    'transferència de particular',
    'ingres a compte',
    'ingrés a compte',
    'ajuda familiar',
  ];
  return markers.any(haystack.contains);
}

double calculatePersonalTransferIncome({
  required List<Transaction> cycleTransactions,
  required List<Category> categories,
  required LedgerLookups lookups,
}) {
  final categoryNames = {
    for (final category in categories) category.id: category.name
  };
  final subcategoryNames = <String, String>{
    for (final category in categories)
      for (final subcategory in category.subcategories)
        '${category.id}:${subcategory.id}': subcategory.name,
  };
  var total = 0.0;
  for (final transaction in cycleTransactions) {
    final classification = classifyTransaction(transaction, lookups);
    if (classification.bucket != LedgerBucket.income) continue;
    if (isPersonalTransferIncome(
      transaction,
      currentCategoryName: categoryNames[transaction.categoryId] ?? '',
      currentSubcategoryName: subcategoryNames[
              '${transaction.categoryId}:${transaction.subCategoryId}'] ??
          '',
    )) {
      total += classification.delta;
    }
  }
  return total;
}
