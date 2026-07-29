import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/budget_entry.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/models/cycle_report.dart';
import 'package:centim/presentation/providers/budget_provider.dart';

void main() {
  group('Category & SubCategory archived deserialization defaults', () {
    test('Category.fromJson without archived field defaults to false', () {
      final json = {
        'id': 'cat_1',
        'name': 'Alimentació',
        'icon': '🛒',
        'subcategories': [
          {
            'id': 'sub_1',
            'name': 'Supermercat',
            'monthlyBudget': 300.0,
            'isFixed': false,
            'isWatched': false,
          }
        ],
        'type': 'expense',
      };

      final category = Category.fromJson(json);
      expect(category.archived, false);
      expect(category.subcategories.first.archived, false);
    });

    test('Category and SubCategory deserialize archived boolean correctly', () {
      final json = {
        'id': 'cat_2',
        'name': 'Oci',
        'icon': '🎉',
        'archived': true,
        'subcategories': [
          {
            'id': 'sub_2',
            'name': 'Cinema',
            'monthlyBudget': 50.0,
            'archived': true,
          }
        ],
        'type': 'expense',
      };

      final category = Category.fromJson(json);
      expect(category.archived, true);
      expect(category.subcategories.first.archived, true);
    });
  });

  group('Effective Budget calculation with archived categories/subcategories',
      () {
    test(
        'Archived subcategory is excluded from active total budget (default monthlyBudget)',
        () {
      const activeSub = SubCategory(
        id: 'sub_active',
        name: 'Activa',
        monthlyBudget: 200.0,
        archived: false,
      );

      const archivedSub = SubCategory(
        id: 'sub_archived',
        name: 'Arxivada',
        monthlyBudget: 150.0,
        archived: true,
      );

      const category = Category(
        id: 'cat_test',
        name: 'Test',
        icon: '📝',
        subcategories: [activeSub, archivedSub],
      );

      final activeSubcategories =
          category.subcategories.where((s) => !s.archived).toList();
      final totalEffectiveBudget =
          activeSubcategories.fold(0.0, (sum, s) => sum + s.monthlyBudget);

      expect(totalEffectiveBudget, 200.0);
    });

    test(
        'Archived subcategory is excluded from active total budget even if budget_entry override exists',
        () {
      const activeSub = SubCategory(
        id: 'sub_active',
        name: 'Activa',
        monthlyBudget: 100.0,
        archived: false,
      );

      const archivedSub = SubCategory(
        id: 'sub_archived',
        name: 'Arxivada',
        monthlyBudget: 100.0,
        archived: true,
      );

      const category = Category(
        id: 'cat_test',
        name: 'Test',
        icon: '📝',
        subcategories: [activeSub, archivedSub],
      );

      final budgetEntries = [
        const BudgetEntry(
          id: 'be_1',
          subCategoryId: 'sub_active',
          year: 2026,
          month: 7,
          amount: 120.0,
        ),
        const BudgetEntry(
          id: 'be_2',
          subCategoryId: 'sub_archived',
          year: 2026,
          month: 7,
          amount: 300.0, // Override phantom budget that MUST be ignored
        ),
      ];

      final activeSubcategories =
          category.subcategories.where((s) => !s.archived).toList();

      final totalBudget = activeSubcategories.fold(0.0, (sum, sub) {
        final entry = budgetEntries.firstWhere(
          (e) => e.subCategoryId == sub.id,
          orElse: () => BudgetEntry(
            id: '',
            subCategoryId: '',
            year: 0,
            month: 0,
            amount: sub.monthlyBudget,
          ),
        );
        return sum + (entry.id.isNotEmpty ? entry.amount : sub.monthlyBudget);
      });

      expect(totalBudget, 120.0);
    });

    test(
        'Archiving parent category excludes all its subcategories from active budget',
        () {
      const sub = SubCategory(
        id: 'sub_1',
        name: 'Sub',
        monthlyBudget: 500.0,
        archived: false,
      );

      const category = Category(
        id: 'cat_archived',
        name: 'Parent Archived',
        icon: '📦',
        archived: true,
        subcategories: [sub],
      );

      final allCategories = [category];
      final activeCategories = allCategories.where((c) => !c.archived).toList();

      expect(activeCategories.isEmpty, true);
    });

    test(
        'calculateBudgetStatus excludes an active child when its parent is archived',
        () {
      const category = Category(
        id: 'cat_archived',
        name: 'Parent Archived',
        icon: '📦',
        archived: true,
        subcategories: [
          SubCategory(
            id: 'sub_active',
            name: 'Fill actiu',
            monthlyBudget: 500,
          ),
        ],
      );
      final cycle = BillingCycle(
        id: 'cycle',
        groupId: 'group',
        name: 'Juliol',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final transaction = Transaction(
        id: 'tx',
        groupId: 'group',
        date: DateTime(2026, 7, 10),
        amount: 125,
        concept: 'Despesa',
        categoryId: category.id,
        subCategoryId: 'sub_active',
        categoryName: category.name,
        subCategoryName: 'Fill actiu',
        payer: 'Eloi',
        isIncome: false,
      );

      final statuses = calculateBudgetStatus(
        [category],
        [transaction],
        const [],
        cycle,
      );

      expect(statuses, isEmpty);
    });

    test('archive then unarchive restores the same budget and spent amount',
        () {
      Category category({required bool archived}) => Category(
            id: 'cat',
            name: 'Vida',
            icon: '🏠',
            subcategories: [
              SubCategory(
                id: 'sub',
                name: 'Casa',
                monthlyBudget: 300,
                archived: archived,
              ),
            ],
          );
      final cycle = BillingCycle(
        id: 'cycle',
        groupId: 'group',
        name: 'Juliol',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final transaction = Transaction(
        id: 'tx',
        groupId: 'group',
        date: DateTime(2026, 7, 15),
        amount: 90,
        concept: 'Casa',
        categoryId: 'cat',
        subCategoryId: 'sub',
        categoryName: 'Vida',
        subCategoryName: 'Casa',
        payer: 'Eloi',
        isIncome: false,
      );

      final before = calculateBudgetStatus(
              [category(archived: false)], [transaction], const [], cycle)
          .single;
      final archived = calculateBudgetStatus(
              [category(archived: true)], [transaction], const [], cycle)
          .single;
      final restored = calculateBudgetStatus(
              [category(archived: false)], [transaction], const [], cycle)
          .single;

      expect(archived.total, 0);
      expect(archived.subcategoryStatuses, isEmpty);
      expect(restored.total, before.total);
      expect(restored.spent, before.spent);
    });

    test('historical mode keeps archived budget and spent together', () {
      const category = Category(
        id: 'cat',
        name: 'Històrica',
        icon: '🗃️',
        archived: true,
        subcategories: [
          SubCategory(
            id: 'sub',
            name: 'Antiga',
            monthlyBudget: 125,
            archived: true,
          ),
        ],
      );
      final cycle = BillingCycle(
        id: 'cycle',
        groupId: 'group',
        name: 'Març',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
      );
      final transaction = Transaction(
        id: 'tx',
        groupId: 'group',
        date: DateTime(2026, 3, 10),
        amount: 80,
        concept: 'Històric',
        categoryId: 'cat',
        subCategoryId: 'sub',
        categoryName: 'Històrica',
        subCategoryName: 'Antiga',
        payer: 'Eloi',
        isIncome: false,
      );

      final status = calculateBudgetStatus(
        [category],
        [transaction],
        const [],
        cycle,
        includeArchived: true,
      ).single;
      expect(status.total, 125);
      expect(status.spent, 80);
    });
  });

  test('serialized cycle report stays intact after archiving its source', () {
    final report = CycleReport(
      id: 'cycle',
      groupId: 'group',
      cycleId: 'cycle',
      generatedAt: DateTime.utc(2026, 7, 31),
      aiVerdict: 'Snapshot',
      totalIncome: 2599.38,
      totalExpense: 1234.56,
      savingsPercentage: 52.5,
      topOverspent: const [
        {
          'categoria': 'Oci',
          'despesa': 250.0,
          'pressupost': 100.0,
          'desviacio': 150.0,
        },
      ],
      schemaVersion: 2,
    );
    final stored = report.toJson();

    // Decisió posterior que no forma part del document ja segellat.
    const archivedLater = SubCategory(
      id: 'oci',
      name: 'Oci',
      monthlyBudget: 100,
      archived: true,
    );
    expect(archivedLater.archived, isTrue);

    final reread = CycleReport.fromJson(stored);
    expect(reread.totalIncome, report.totalIncome);
    expect(reread.totalExpense, report.totalExpense);
    expect(reread.savingsPercentage, report.savingsPercentage);
    expect(reread.topOverspent, report.topOverspent);
    expect(reread.schemaVersion, report.schemaVersion);
  });
}
