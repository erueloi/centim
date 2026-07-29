import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transfer.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';

part 'transfer_provider.g.dart';

@riverpod
class TransferNotifier extends _$TransferNotifier {
  @override
  Stream<List<Transfer>> build() {
    final groupIdAsync = ref.watch(currentGroupIdProvider);

    return groupIdAsync.when(
      data: (groupId) {
        if (groupId == null) return Stream.value([]);
        final repository = ref.read(transferRepositoryProvider);
        return repository.getTransfersStream(groupId);
      },
      loading: () => const Stream.empty(),
      error: (_, __) => const Stream.empty(),
    );
  }

  Future<void> addTransfer({
    required double amount,
    required String sourceAssetId,
    required String sourceAssetName,
    required TransferDestinationType destinationType,
    required String destinationId,
    required String destinationName,
    required DateTime date,
    String? note,
    String? concept,
    String source = 'manual',
    List<BankTransferLeg> bankLegs = const [],
    bool awaitsBankCounterpart = false,
  }) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');

    final transfer = Transfer(
      id: const Uuid().v4(),
      groupId: groupId,
      date: date,
      amount: amount,
      sourceAssetId: sourceAssetId,
      sourceAssetName: sourceAssetName,
      destinationType: destinationType,
      destinationId: destinationId,
      destinationName: destinationName,
      note: note,
      concept: concept,
      source: source,
      bankLegs: bankLegs,
      awaitsBankCounterpart: awaitsBankCounterpart,
    );

    final repo = ref.read(transferRepositoryProvider);
    await repo.addTransfer(groupId, transfer);
  }

  Future<void> updateTransfer(Transfer newTransfer) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    final transfers = await future;
    final matchingTransfers = transfers.where((t) => t.id == newTransfer.id);
    if (matchingTransfers.isEmpty) return;
    final oldTransfer = matchingTransfers.first;

    final repo = ref.read(transferRepositoryProvider);
    await repo.mutateTransfer(
      groupId: groupId,
      oldTransfer: oldTransfer,
      newTransfer: newTransfer,
    );
  }

  Future<void> deleteTransfer(String transferId) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    // Find the transfer to reverse balances
    final transfers = await future;
    final matchingTransfers = transfers.where((t) => t.id == transferId);
    if (matchingTransfers.isEmpty) return;
    final transfer = matchingTransfers.first;

    final repo = ref.read(transferRepositoryProvider);
    await repo.mutateTransfer(groupId: groupId, oldTransfer: transfer);
  }
}
