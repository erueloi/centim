import '../models/category.dart';
import '../models/transaction.dart';

/// Efecte d'un moviment sobre UNA guardiola.
///
/// Precedència D5: `savingsGoalId` explícit mana sobre l'enllaç de la
/// subcategoria.
({String goalId, double delta})? goalEffectForTransaction(
  Transaction tx,
  List<Category> categories,
) {
  if (tx.savingsGoalId != null) {
    return (goalId: tx.savingsGoalId!, delta: -tx.amount);
  }
  final links = linksForSubcategory(tx.subCategoryId, categories);
  if (links.goalId == null) return null;
  return (
    goalId: links.goalId!,
    delta: tx.isIncome ? -tx.amount : tx.amount,
  );
}

({String? goalId, String? debtId}) linksForSubcategory(
  String subCategoryId,
  List<Category> categories,
) {
  for (final category in categories) {
    for (final subcategory in category.subcategories) {
      if (subcategory.id == subCategoryId) {
        return (
          goalId: subcategory.linkedSavingsGoalId,
          debtId: subcategory.linkedDebtId,
        );
      }
    }
  }
  return (goalId: null, debtId: null);
}
