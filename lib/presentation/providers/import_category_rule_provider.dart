import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repository_providers.dart';
import '../../domain/models/import_category_rule.dart';
import 'auth_providers.dart';

final importCategoryRulesProvider =
    StreamProvider<List<ImportCategoryRule>>((ref) async* {
  final groupId = await ref.watch(currentGroupIdProvider.future);
  if (groupId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(importCategoryRuleRepositoryProvider).watchRules(groupId);
});
