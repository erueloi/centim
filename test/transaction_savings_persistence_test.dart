import 'package:centim/data/repositories/firestore_transaction_repository.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/ledger_service.dart';
import 'package:centim/presentation/providers/transaction_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const categories = [
    Category(
      id: 'expense',
      name: 'Despesa',
      icon: '',
      subcategories: [
        SubCategory(
          id: 'linked-sub',
          name: 'Enllaçada A',
          monthlyBudget: 0,
          linkedSavingsGoalId: 'goalA',
        ),
      ],
    ),
  ];

  final transaction = Transaction(
    id: 'tx1',
    groupId: 'g',
    date: DateTime.utc(2026, 7, 10, 12),
    amount: 42,
    concept: 'Pagar amb estalvis',
    categoryId: 'expense',
    subCategoryId: 'linked-sub',
    categoryName: 'Despesa',
    subCategoryName: 'Enllaçada A',
    payer: 'Eloi',
    savingsGoalId: 'goalB',
  );

  test('savingsGoalId sobreviu el round-trip de Firestore', () {
    final map = transactionToFirestoreMap(transaction);
    expect(map['savingsGoalId'], 'goalB');

    final restored = transactionFromFirestoreMap(map, 'tx1');
    expect(restored.savingsGoalId, 'goalB');
    expect(restored.date.toUtc(), transaction.date.toUtc());
  });

  test('D5: després del round-trip mana savingsGoalId sobre l’enllaç', () {
    final restored = transactionFromFirestoreMap(
      transactionToFirestoreMap(transaction),
      'tx1',
    );

    final effect = goalEffectForTransaction(restored, categories);
    expect(effect?.goalId, 'goalB');
    expect(effect?.delta, -42);

    final classified = classifyTransaction(
      restored,
      LedgerLookups.from(categories),
    );
    expect(
      classified.incoherences.any((item) => item.type == 'guardiola-creuada'),
      isTrue,
    );
  });
}
