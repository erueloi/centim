import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/import_category_rule.dart';

void main() {
  ImportCategoryRule rule({
    required String id,
    required List<String> fragments,
    required String subcategory,
    int priority = 0,
    ImportRuleDirection direction = ImportRuleDirection.income,
  }) =>
      ImportCategoryRule(
        id: id,
        groupId: 'group',
        name: id,
        requiredFragments: fragments,
        direction: direction,
        bankAccountKey: null,
        categoryId: 'income',
        subCategoryId: subcategory,
        enabled: true,
        priority: priority,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  test('punctuation changes do not prevent a match', () {
    final item = rule(
      id: 'mare',
      fragments: ['marta berenguer pla', 'ajuda eloi'],
      subcategory: 'bizum',
    );
    expect(
      importRuleMatches(
        rule: item,
        concept: 'MARTA;BERENGUER;PLA — Ajuda Eloi',
        signedAmount: 50,
        bankAccountKey: null,
      ),
      isTrue,
    );
  });

  test('same sender can resolve to different targets by concept', () {
    final ajuda = rule(
      id: 'ajuda',
      fragments: ['isidre aymerich oliveda', 'ajuda eloi'],
      subcategory: 'bizum',
    );
    final pagament = rule(
      id: 'pagament',
      fragments: ['isidre aymerich oliveda', 'pagament eloi'],
      subcategory: 'account-income',
    );

    expect(
      bestMatchingImportRule(
        rules: [ajuda, pagament],
        concept: 'ISIDRE AYMERICH OLIVEDA — Pagament Eloi',
        signedAmount: 150,
        bankAccountKey: null,
      )?.subCategoryId,
      'account-income',
    );
  });

  test('higher priority wins and direction is respected', () {
    final broad = rule(
      id: 'broad',
      fragments: ['isidre'],
      subcategory: 'broad',
      priority: 1,
    );
    final precise = rule(
      id: 'precise',
      fragments: ['isidre', 'pagament eloi'],
      subcategory: 'precise',
      priority: 10,
    );
    expect(
      bestMatchingImportRule(
        rules: [broad, precise],
        concept: 'ISIDRE — Pagament Eloi',
        signedAmount: 150,
        bankAccountKey: null,
      )?.subCategoryId,
      'precise',
    );
    expect(
      bestMatchingImportRule(
        rules: [broad, precise],
        concept: 'ISIDRE — Pagament Eloi',
        signedAmount: -150,
        bankAccountKey: null,
      ),
      isNull,
    );
  });
}
