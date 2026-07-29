import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/repository_providers.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/import_category_rule.dart';
import '../../providers/auth_providers.dart';
import '../../providers/category_notifier.dart';
import '../../providers/import_category_rule_provider.dart';

class ImportRulesScreen extends ConsumerWidget {
  const ImportRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(importCategoryRulesProvider);
    final categories =
        ref.watch(categoryNotifierProvider).valueOrNull ?? const <Category>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Regles d’importació')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: categories.isEmpty
            ? null
            : () => showImportRuleEditor(
                  context,
                  ref,
                  categories: categories,
                ),
        icon: const Icon(Icons.add),
        label: const Text('Nova regla'),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Encara no hi ha regles. Les regles només suggereixen una '
                    'categoria: tu sempre confirmes la importació.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final rule = items[index];
                  final target = _targetName(categories, rule);
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        rule.enabled ? Icons.auto_awesome : Icons.pause_circle,
                        color: rule.enabled ? Colors.teal : Colors.grey,
                      ),
                      title: Text(rule.name),
                      subtitle: Text(
                        '${rule.requiredFragments.join(' + ')}\n'
                        '$target · prioritat ${rule.priority}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await showImportRuleEditor(
                              context,
                              ref,
                              categories: categories,
                              existing: rule,
                            );
                          } else if (value == 'toggle') {
                            await ref
                                .read(importCategoryRuleRepositoryProvider)
                                .saveRule(
                                  rule.copyWith(
                                    enabled: !rule.enabled,
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                          } else if (value == 'delete') {
                            await ref
                                .read(importCategoryRuleRepositoryProvider)
                                .deleteRule(rule.groupId, rule.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edita'),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(rule.enabled ? 'Desactiva' : 'Activa'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Elimina'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _targetName(
    List<Category> categories,
    ImportCategoryRule rule,
  ) {
    final categoryMatches =
        categories.where((category) => category.id == rule.categoryId);
    if (categoryMatches.isEmpty) return 'Destinació inexistent';
    final category = categoryMatches.first;
    final subMatches = category.subcategories
        .where((subcategory) => subcategory.id == rule.subCategoryId);
    final subName =
        subMatches.isEmpty ? 'Subcategoria inexistent' : subMatches.first.name;
    final archived = category.archived ||
        (subMatches.isNotEmpty && subMatches.first.archived);
    return '${category.name} › $subName${archived ? ' · arxivada' : ''}';
  }
}

Future<bool> showImportRuleEditor(
  BuildContext context,
  WidgetRef ref, {
  required List<Category> categories,
  ImportCategoryRule? existing,
  String? initialConcept,
  String? initialCategoryId,
  String? initialSubCategoryId,
  double? initialSignedAmount,
  String? initialBankAccountKey,
}) async {
  final activeCategories =
      categories.where((category) => !category.archived).toList();
  if (activeCategories.isEmpty) return false;

  final nameController = TextEditingController(
    text: existing?.name ??
        (initialConcept == null ? '' : 'Regla per ${initialConcept.trim()}'),
  );
  final fragmentsController = TextEditingController(
    text: existing?.requiredFragments.join(', ') ??
        normalizeImportConcept(initialConcept ?? ''),
  );
  final accountController = TextEditingController(
    text: existing?.bankAccountKey ?? initialBankAccountKey ?? '',
  );
  final priorityController =
      TextEditingController(text: '${existing?.priority ?? 0}');
  var categoryId = existing?.categoryId ?? initialCategoryId;
  if (!activeCategories.any((category) => category.id == categoryId)) {
    categoryId = activeCategories.first.id;
  }
  var selectedCategory =
      activeCategories.firstWhere((category) => category.id == categoryId);
  var subcategoryId = existing?.subCategoryId ?? initialSubCategoryId;
  final initialSubcategories = selectedCategory.subcategories
      .where((subcategory) => !subcategory.archived)
      .toList();
  if (!initialSubcategories
      .any((subcategory) => subcategory.id == subcategoryId)) {
    subcategoryId =
        initialSubcategories.isEmpty ? null : initialSubcategories.first.id;
  }
  var direction = existing?.direction ??
      (initialSignedAmount == null
          ? ImportRuleDirection.any
          : initialSignedAmount > 0
              ? ImportRuleDirection.income
              : ImportRuleDirection.expense);

  final result = await showDialog<ImportCategoryRule>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        selectedCategory = activeCategories
            .firstWhere((category) => category.id == categoryId);
        final subcategories = selectedCategory.subcategories
            .where((subcategory) => !subcategory.archived)
            .toList();
        return AlertDialog(
          title: Text(existing == null ? 'Nova regla' : 'Edita la regla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: fragmentsController,
                  decoration: const InputDecoration(
                    labelText: 'Fragments obligatoris',
                    helperText: 'Separa fragments independents amb comes.',
                  ),
                ),
                DropdownButtonFormField<ImportRuleDirection>(
                  initialValue: direction,
                  decoration: const InputDecoration(labelText: 'Direcció'),
                  items: const [
                    DropdownMenuItem(
                      value: ImportRuleDirection.any,
                      child: Text('Qualsevol'),
                    ),
                    DropdownMenuItem(
                      value: ImportRuleDirection.income,
                      child: Text('Ingrés'),
                    ),
                    DropdownMenuItem(
                      value: ImportRuleDirection.expense,
                      child: Text('Despesa'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => direction = value ?? direction),
                ),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: activeCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text('${category.icon} ${category.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    categoryId = value;
                    final category =
                        activeCategories.firstWhere((item) => item.id == value);
                    final activeSubs = category.subcategories
                        .where((item) => !item.archived)
                        .toList();
                    subcategoryId =
                        activeSubs.isEmpty ? null : activeSubs.first.id;
                  }),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('subcategory-$categoryId'),
                  initialValue:
                      subcategories.any((item) => item.id == subcategoryId)
                          ? subcategoryId
                          : null,
                  decoration: const InputDecoration(labelText: 'Subcategoria'),
                  items: subcategories
                      .map(
                        (subcategory) => DropdownMenuItem(
                          value: subcategory.id,
                          child: Text(subcategory.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => subcategoryId = value),
                ),
                TextField(
                  controller: accountController,
                  decoration: const InputDecoration(
                    labelText: 'Clau bancària (opcional)',
                  ),
                ),
                TextField(
                  controller: priorityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prioritat'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel·la'),
            ),
            FilledButton(
              onPressed: categoryId == null || subcategoryId == null
                  ? null
                  : () async {
                      final fragments = fragmentsController.text
                          .split(',')
                          .map(normalizeImportConcept)
                          .where((value) => value.isNotEmpty)
                          .toList();
                      if (nameController.text.trim().isEmpty ||
                          fragments.isEmpty) {
                        return;
                      }
                      final groupId =
                          await ref.read(currentGroupIdProvider.future);
                      if (groupId == null || !dialogContext.mounted) return;
                      final now = DateTime.now();
                      Navigator.pop(
                        dialogContext,
                        ImportCategoryRule(
                          id: existing?.id ?? '',
                          groupId: groupId,
                          name: nameController.text.trim(),
                          requiredFragments: fragments,
                          direction: direction,
                          bankAccountKey: accountController.text.trim().isEmpty
                              ? null
                              : accountController.text.trim(),
                          categoryId: categoryId!,
                          subCategoryId: subcategoryId!,
                          enabled: existing?.enabled ?? true,
                          priority: int.tryParse(priorityController.text) ?? 0,
                          createdAt: existing?.createdAt ?? now,
                          updatedAt: now,
                        ),
                      );
                    },
              child: const Text('Desa'),
            ),
          ],
        );
      },
    ),
  );

  nameController.dispose();
  fragmentsController.dispose();
  accountController.dispose();
  priorityController.dispose();
  if (result == null) return false;
  await ref.read(importCategoryRuleRepositoryProvider).saveRule(result);
  return true;
}
