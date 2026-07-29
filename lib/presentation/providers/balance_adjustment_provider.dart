import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repository_providers.dart';
import '../../domain/models/balance_adjustment.dart';
import 'auth_providers.dart';

final balanceAdjustmentsProvider =
    StreamProvider<List<BalanceAdjustment>>((ref) async* {
  final groupId = await ref.watch(currentGroupIdProvider.future);
  if (groupId == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(balanceAdjustmentRepositoryProvider)
      .watchAdjustments(groupId);
});

final balanceAdjustmentsForGoalProvider =
    Provider.family<List<BalanceAdjustment>, String>((ref, goalId) {
  final all = ref.watch(balanceAdjustmentsProvider).valueOrNull ?? const [];
  return all
      .where((adjustment) => adjustment.savingsGoalId == goalId)
      .toList(growable: false);
});
