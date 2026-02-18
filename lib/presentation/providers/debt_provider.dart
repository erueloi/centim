import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/debt_account.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';

part 'debt_provider.g.dart';

@riverpod
class DebtNotifier extends _$DebtNotifier {
  @override
  Stream<List<DebtAccount>> build() {
    final groupIdAsync = ref.watch(currentGroupIdProvider);

    return groupIdAsync.when(
      data: (groupId) {
        if (groupId == null) return Stream.value([]);
        final repository = ref.read(debtRepositoryProvider);
        return repository.getDebtsStream(groupId);
      },
      loading: () => const Stream.empty(),
      error: (_, _) => const Stream.empty(),
    );
  }

  Future<void> addDebt(DebtAccount debt) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');
    await ref.read(debtRepositoryProvider).addDebt(groupId, debt);
  }

  Future<void> updateDebt(DebtAccount debt) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');
    await ref.read(debtRepositoryProvider).updateDebt(groupId, debt);
  }

  Future<void> deleteDebt(String debtId) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');
    await ref.read(debtRepositoryProvider).deleteDebt(groupId, debtId);
  }
}
