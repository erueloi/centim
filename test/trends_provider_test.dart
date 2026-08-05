import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/presentation/providers/trends_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Transaction transaction({
    required String id,
    required DateTime date,
    required double amount,
    required String categoryId,
    required String subcategoryId,
    required String categoryName,
    required String subcategoryName,
    bool isIncome = false,
    String? savingsGoalId,
  }) {
    return Transaction(
      id: id,
      groupId: 'group',
      date: date,
      amount: amount,
      concept: id,
      categoryId: categoryId,
      subCategoryId: subcategoryId,
      categoryName: categoryName,
      subCategoryName: subcategoryName,
      payer: 'Eloi',
      isIncome: isIncome,
      savingsGoalId: savingsGoalId,
    );
  }

  test(
      'agrupa snapshots amb noms antics per subCategoryId i mostra el nom actual',
      () {
    const food = Category(
      id: 'food',
      name: 'Menjar / Compres',
      icon: '🍽️',
      subcategories: [
        SubCategory(
          id: 'market',
          name: 'Mercat / Supermercat',
          monthlyBudget: 0,
        ),
        SubCategory(
          id: 'coffee',
          name: 'Esmorzar / Cafè',
          monthlyBudget: 0,
        ),
      ],
    );
    final data = calculateTrendsData(
      transactions: [
        transaction(
          id: 'old-market',
          date: DateTime(2026, 1, 10),
          amount: 1129,
          categoryId: 'food',
          subcategoryId: 'market',
          categoryName: 'Menjar',
          subcategoryName: 'Supermercat',
        ),
        transaction(
          id: 'new-market',
          date: DateTime(2026, 2, 10),
          amount: 1717,
          categoryId: 'food',
          subcategoryId: 'market',
          categoryName: 'Menjar / Compres',
          subcategoryName: 'Mercat / Supermercat',
        ),
        transaction(
          id: 'old-coffee',
          date: DateTime(2026, 2, 11),
          amount: 154,
          categoryId: 'food',
          subcategoryId: 'coffee',
          categoryName: 'Menjar',
          subcategoryName: 'Café',
        ),
        transaction(
          id: 'new-coffee',
          date: DateTime(2026, 3, 11),
          amount: 44,
          categoryId: 'food',
          subcategoryId: 'coffee',
          categoryName: 'Menjar / Compres',
          subcategoryName: 'Esmorzar / Cafè',
        ),
      ],
      categories: const [food],
      selectedFilter: TrendsTimeFilter.thisYear,
      now: DateTime(2026, 8, 5),
    );

    final category = data.topCategories.single;
    expect(category.category.name, 'Menjar / Compres');
    expect(category.subcategories, hasLength(2));
    expect(category.subcategories.first.id, 'market');
    expect(category.subcategories.first.name, 'Mercat / Supermercat');
    expect(category.subcategories.first.totalAmount, 2846);
    expect(category.subcategories.last.id, 'coffee');
    expect(category.subcategories.last.name, 'Esmorzar / Cafè');
    expect(category.subcategories.last.totalAmount, 198);
  });

  test('no crea zeros per mesos sense dades i exclou el mes actual del 12m',
      () {
    const expense = Category(id: 'expense', name: 'Vida', icon: '🏠');
    final data = calculateTrendsData(
      transactions: [
        transaction(
          id: 'january',
          date: DateTime(2026, 1, 4),
          amount: 20,
          categoryId: 'expense',
          subcategoryId: '',
          categoryName: 'Vida',
          subcategoryName: '',
        ),
        transaction(
          id: 'august',
          date: DateTime(2026, 8, 2),
          amount: 30,
          categoryId: 'expense',
          subcategoryId: '',
          categoryName: 'Vida',
          subcategoryName: '',
        ),
      ],
      categories: const [expense],
      selectedFilter: TrendsTimeFilter.thisYear,
      now: DateTime(2026, 8, 5),
    );

    expect(data.monthlyFlow, hasLength(1));
    expect(data.monthlyFlow.single.month, DateTime(2026, 1));
    expect(data.currentMonthExcludedFromFlow, isTrue);
  });

  test('el filtre Mes conserva i marca el punt actual com a incomplet', () {
    const expense = Category(id: 'expense', name: 'Vida', icon: '🏠');
    final data = calculateTrendsData(
      transactions: [
        transaction(
          id: 'august',
          date: DateTime(2026, 8, 2),
          amount: 30,
          categoryId: 'expense',
          subcategoryId: '',
          categoryName: 'Vida',
          subcategoryName: '',
        ),
      ],
      categories: const [expense],
      selectedFilter: TrendsTimeFilter.thisMonth,
      now: DateTime(2026, 8, 5),
    );

    expect(data.monthlyFlow.single.isIncomplete, isTrue);
    expect(data.currentMonthExcludedFromFlow, isFalse);
  });

  test('mostra vuit categories i deixa una cua Altres auditable', () {
    final categories = List.generate(
      10,
      (index) => Category(
        id: 'category-$index',
        name: 'Categoria $index',
        icon: '•',
      ),
    );
    final transactions = List.generate(
      10,
      (index) => transaction(
        id: 'transaction-$index',
        date: DateTime(2026, 1, 10),
        amount: (10 - index).toDouble(),
        categoryId: 'category-$index',
        subcategoryId: '',
        categoryName: 'Nom antic $index',
        subcategoryName: '',
      ),
    );
    final data = calculateTrendsData(
      transactions: transactions,
      categories: categories,
      selectedFilter: TrendsTimeFilter.thisYear,
      now: DateTime(2026, 8, 5),
    );

    expect(data.topCategories, hasLength(9));
    final others = data.topCategories.last;
    expect(others.category.id, 'others');
    expect(others.categoryIds, {'category-8', 'category-9'});
    expect(others.totalAmount, 3);
    expect(others.subcategories.map((item) => item.name),
        ['Categoria 8', 'Categoria 9']);
  });

  test('la taxa usa ingressos i despeses del ledger, no moviments de guardiola',
      () {
    const income = Category(
      id: 'income',
      name: 'Ingressos',
      icon: '+',
      type: TransactionType.income,
    );
    const expense = Category(id: 'expense', name: 'Vida', icon: '-');
    const savings = Category(
      id: 'savings',
      name: 'Estalvi',
      icon: 'S',
      subcategories: [
        SubCategory(
          id: 'goal',
          name: 'Guardiola',
          monthlyBudget: 0,
          linkedSavingsGoalId: 'goal-id',
        ),
      ],
    );
    final data = calculateTrendsData(
      transactions: [
        transaction(
          id: 'income',
          date: DateTime(2026, 1, 1),
          amount: 1000,
          categoryId: 'income',
          subcategoryId: '',
          categoryName: 'Ingressos',
          subcategoryName: '',
          isIncome: true,
        ),
        transaction(
          id: 'expense',
          date: DateTime(2026, 1, 2),
          amount: 800,
          categoryId: 'expense',
          subcategoryId: '',
          categoryName: 'Vida',
          subcategoryName: '',
        ),
        transaction(
          id: 'saving',
          date: DateTime(2026, 1, 3),
          amount: 100,
          categoryId: 'savings',
          subcategoryId: 'goal',
          categoryName: 'Estalvi',
          subcategoryName: 'Guardiola',
        ),
      ],
      categories: const [income, expense, savings],
      selectedFilter: TrendsTimeFilter.thisYear,
      now: DateTime(2026, 8, 5),
    );

    expect(data.savingsRate, closeTo(0.20, 0.000001));
    expect(data.topCategories.single.category.id, 'expense');
  });

  test('els missatges de taxa respecten els nous llindars', () {
    expect(savingsRateMessage(0.049), 'Molt just');
    expect(savingsRateMessage(0.05), 'Millorable');
    expect(savingsRateMessage(0.10), 'Vas bé');
    expect(savingsRateMessage(0.20), 'Vas bé');
    expect(savingsRateMessage(0.201), 'Molt bé');
  });
}
