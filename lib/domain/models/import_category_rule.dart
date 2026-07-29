import 'package:cloud_firestore/cloud_firestore.dart';

enum ImportRuleDirection { any, income, expense }

String normalizeImportConcept(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-zà-öø-ÿ0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class ImportCategoryRule {
  final String id;
  final String groupId;
  final String name;
  final List<String> requiredFragments;
  final ImportRuleDirection direction;
  final String? bankAccountKey;
  final String categoryId;
  final String subCategoryId;
  final bool enabled;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ImportCategoryRule({
    required this.id,
    required this.groupId,
    required this.name,
    required this.requiredFragments,
    required this.direction,
    required this.bankAccountKey,
    required this.categoryId,
    required this.subCategoryId,
    required this.enabled,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  ImportCategoryRule copyWith({
    String? id,
    String? groupId,
    String? name,
    List<String>? requiredFragments,
    ImportRuleDirection? direction,
    String? bankAccountKey,
    bool clearBankAccountKey = false,
    String? categoryId,
    String? subCategoryId,
    bool? enabled,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImportCategoryRule(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      requiredFragments: requiredFragments ?? this.requiredFragments,
      direction: direction ?? this.direction,
      bankAccountKey:
          clearBankAccountKey ? null : (bankAccountKey ?? this.bankAccountKey),
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'groupId': groupId,
        'name': name,
        'requiredFragments': requiredFragments,
        'direction': direction.name,
        'bankAccountKey': bankAccountKey,
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
        'enabled': enabled,
        'priority': priority,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ImportCategoryRule.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime readDate(Object? value) =>
        value is Timestamp ? value.toDate() : DateTime.now();
    return ImportCategoryRule(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      name: data['name'] as String? ?? 'Regla',
      requiredFragments: (data['requiredFragments'] as List? ?? const [])
          .whereType<String>()
          .map(normalizeImportConcept)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      direction: ImportRuleDirection.values.firstWhere(
        (value) => value.name == data['direction'],
        orElse: () => ImportRuleDirection.any,
      ),
      bankAccountKey: data['bankAccountKey'] as String?,
      categoryId: data['categoryId'] as String? ?? '',
      subCategoryId: data['subCategoryId'] as String? ?? '',
      enabled: data['enabled'] as bool? ?? true,
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }
}

bool importRuleMatches({
  required ImportCategoryRule rule,
  required String concept,
  required double signedAmount,
  required String? bankAccountKey,
}) {
  if (!rule.enabled || rule.requiredFragments.isEmpty) return false;
  if (rule.direction == ImportRuleDirection.income && signedAmount <= 0) {
    return false;
  }
  if (rule.direction == ImportRuleDirection.expense && signedAmount >= 0) {
    return false;
  }
  if (rule.bankAccountKey != null &&
      rule.bankAccountKey!.isNotEmpty &&
      rule.bankAccountKey != bankAccountKey) {
    return false;
  }
  final normalized = normalizeImportConcept(concept);
  return rule.requiredFragments.every(normalized.contains);
}

ImportCategoryRule? bestMatchingImportRule({
  required Iterable<ImportCategoryRule> rules,
  required String concept,
  required double signedAmount,
  required String? bankAccountKey,
}) {
  final matches = rules
      .where(
        (rule) => importRuleMatches(
          rule: rule,
          concept: concept,
          signedAmount: signedAmount,
          bankAccountKey: bankAccountKey,
        ),
      )
      .toList()
    ..sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      if (priority != 0) return priority;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  return matches.isEmpty ? null : matches.first;
}
