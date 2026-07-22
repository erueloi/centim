import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/budget_entry.dart';
import 'package:centim/domain/models/billing_cycle.dart';

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

  group('Effective Budget calculation with archived categories/subcategories', () {
    test('Archived subcategory is excluded from active total budget (default monthlyBudget)', () {
      final activeSub = const SubCategory(
        id: 'sub_active',
        name: 'Activa',
        monthlyBudget: 200.0,
        archived: false,
      );

      final archivedSub = const SubCategory(
        id: 'sub_archived',
        name: 'Arxivada',
        monthlyBudget: 150.0,
        archived: true,
      );

      final category = Category(
        id: 'cat_test',
        name: 'Test',
        icon: '📝',
        subcategories: [activeSub, archivedSub],
      );

      final activeSubcategories = category.subcategories.where((s) => !s.archived).toList();
      final totalEffectiveBudget = activeSubcategories.fold(0.0, (sum, s) => sum + s.monthlyBudget);

      expect(totalEffectiveBudget, 200.0);
    });

    test('Archived subcategory is excluded from active total budget even if budget_entry override exists', () {
      final activeSub = const SubCategory(
        id: 'sub_active',
        name: 'Activa',
        monthlyBudget: 100.0,
        archived: false,
      );

      final archivedSub = const SubCategory(
        id: 'sub_archived',
        name: 'Arxivada',
        monthlyBudget: 100.0,
        archived: true,
      );

      final category = Category(
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

      final activeSubcategories = category.subcategories.where((s) => !s.archived).toList();

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

    test('Archiving parent category excludes all its subcategories from active budget', () {
      final sub = const SubCategory(
        id: 'sub_1',
        name: 'Sub',
        monthlyBudget: 500.0,
        archived: false,
      );

      final category = Category(
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
  });
}
