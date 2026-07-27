import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/services/ledger_service.dart';

void main() {
  // ── Categories de prova ──
  final incomeCat = Category(
    id: 'inc',
    name: 'Ingressos',
    icon: '',
    type: TransactionType.income,
    subcategories: const [
      SubCategory(id: 'inc_bizum', name: 'Bizum', monthlyBudget: 0),
      SubCategory(
        id: 'inc_guard',
        name: 'Ingrés guardiola',
        monthlyBudget: 0,
        linkedSavingsGoalId: 'goalA',
      ),
    ],
  );
  final expenseCat = Category(
    id: 'exp',
    name: 'Menjar',
    icon: '',
    type: TransactionType.expense,
    subcategories: const [
      SubCategory(id: 'exp_super', name: 'Super', monthlyBudget: 0),
    ],
  );
  final savingsCat = Category(
    id: 'sav',
    name: 'Estalvi',
    icon: '',
    type: TransactionType.expense,
    subcategories: const [
      SubCategory(
        id: 'sav_eloi',
        name: 'Estalvi Eloi',
        monthlyBudget: 400,
        linkedSavingsGoalId: 'goalA',
      ),
    ],
  );
  final look = LedgerLookups.from([incomeCat, expenseCat, savingsCat]);

  Transaction mk({
    required double amount,
    required bool isIncome,
    required String catId,
    required String subId,
    String? savingsGoalId,
  }) =>
      Transaction(
        id: 'x',
        groupId: 'g',
        date: DateTime(2026, 7, 10),
        amount: amount,
        concept: 'c',
        categoryId: catId,
        subCategoryId: subId,
        categoryName: '',
        subCategoryName: '',
        payer: 'p',
        isIncome: isIncome,
        savingsGoalId: savingsGoalId,
      );

  test('un moviment de guardiola no suma als totals', () {
    final s = summarizeLedger(
      [mk(amount: 100, isIncome: false, catId: 'sav', subId: 'sav_eloi')],
      look,
    );
    expect(s.totalExpense, 0);
    expect(s.totalIncome, 0);
    expect(s.savedThisCycle, 100);
  });

  test('retirada de guardiola via savingsGoalId → withdrawn, no ingrés', () {
    final s = summarizeLedger(
      [
        mk(
          amount: 30,
          isIncome: true,
          catId: 'inc',
          subId: 'inc_bizum',
          savingsGoalId: 'goalA',
        )
      ],
      look,
    );
    expect(s.totalIncome, 0);
    expect(s.withdrawnThisCycle, 30);
  });

  test('un refund resta del gastat de la seva categoria, sense incoherència', () {
    final s = summarizeLedger([
      mk(amount: 50, isIncome: false, catId: 'exp', subId: 'exp_super'),
      mk(amount: 20, isIncome: true, catId: 'exp', subId: 'exp_super'),
    ], look);
    expect(s.totalExpense, 30);
    expect(s.expenseByCategory['exp'], 30);
    expect(s.incoherences, isEmpty);
  });

  test('mal tipat (ingrés + isIncome=false) compta com despesa i es marca', () {
    final s = summarizeLedger(
      [mk(amount: 400, isIncome: false, catId: 'inc', subId: 'inc_bizum')],
      look,
    );
    expect(s.totalExpense, 400);
    expect(s.totalIncome, 0);
    expect(s.incoherences.length, 1);
    expect(s.incoherences.first.type, 'tipus');
  });

  test('guardiola exclosa dels totals PERÒ marcada si està mal tipada (cas 400 €)',
      () {
    // Aportació categoritzada a "Ingrés de guardiola Eloi": categoria d'ingrés +
    // isIncome=false + subcategoria enllaçada. Exclosa dels totals I marcada.
    final s = summarizeLedger(
      [mk(amount: 400, isIncome: false, catId: 'inc', subId: 'inc_guard')],
      look,
    );
    expect(s.totalExpense, 0);
    expect(s.totalIncome, 0);
    expect(s.savedThisCycle, 400);
    expect(s.incoherences.any((i) => i.type == 'tipus'), isTrue);
  });

  test('D5: savingsGoalId i subcategoria a guardioles diferents es marca', () {
    final s = summarizeLedger(
      [
        mk(
          amount: 10,
          isIncome: true,
          catId: 'inc',
          subId: 'inc_guard', // enllaçada a goalA
          savingsGoalId: 'goalB', // però el moviment diu goalB
        )
      ],
      look,
    );
    expect(s.incoherences.any((i) => i.type == 'guardiola-creuada'), isTrue);
    expect(s.withdrawnThisCycle, 10); // segueix sent moviment de guardiola
    expect(s.totalIncome, 0);
  });

  test(
      'TEST CLAU: dashboard == trends == cycle_reports (mateixos totals) + invariant',
      () {
    final txs = [
      mk(amount: 1000, isIncome: true, catId: 'inc', subId: 'inc_bizum'),
      mk(amount: 50, isIncome: false, catId: 'exp', subId: 'exp_super'),
      mk(amount: 20, isIncome: true, catId: 'exp', subId: 'exp_super'), // refund
      mk(amount: 400, isIncome: false, catId: 'sav', subId: 'sav_eloi'), // guardiola
    ];

    // Dashboard i cycle_reports: sumen via summarizeLedger.
    final dashboard = summarizeLedger(txs, look);

    // Trends: plega classifyTransaction per moviment (mateixa font).
    double trendsIncome = 0, trendsExpense = 0;
    for (final t in txs) {
      final c = classifyTransaction(t, look);
      if (c.bucket == LedgerBucket.income) trendsIncome += c.delta;
      if (c.bucket == LedgerBucket.expense) trendsExpense += c.delta;
    }

    expect(dashboard.totalIncome, 1000);
    expect(dashboard.totalExpense, 30); // 50 − 20 refund; guardiola exclosa

    // Invariant: total == Σ per categoria.
    final sumInc =
        dashboard.incomeByCategory.values.fold(0.0, (a, b) => a + b);
    final sumExp =
        dashboard.expenseByCategory.values.fold(0.0, (a, b) => a + b);
    expect(sumInc, dashboard.totalIncome);
    expect(sumExp, dashboard.totalExpense);

    // Les tres capes coincideixen EXACTAMENT.
    expect(trendsIncome, dashboard.totalIncome);
    expect(trendsExpense, dashboard.totalExpense);
  });
}
