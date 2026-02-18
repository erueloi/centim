import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transfer.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';
import 'asset_provider.dart';
import 'debt_provider.dart';

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
      error: (_, _) => const Stream.empty(),
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
    );

    // 1. Save the transfer document
    final repo = ref.read(transferRepositoryProvider);
    await repo.addTransfer(groupId, transfer);

    // 2. Update source asset balance (subtract)
    try {
      final assets = await ref.read(assetNotifierProvider.future);
      final source = assets.firstWhere((a) => a.id == sourceAssetId);
      await ref
          .read(assetNotifierProvider.notifier)
          .updateAsset(source.copyWith(amount: source.amount - amount));
    } catch (e) {
      debugPrint('Error updating source asset: $e');
    }

    // 3. Update destination balance
    try {
      if (destinationType == TransferDestinationType.asset) {
        final assets = await ref.read(assetNotifierProvider.future);
        final dest = assets.firstWhere((a) => a.id == destinationId);
        await ref
            .read(assetNotifierProvider.notifier)
            .updateAsset(dest.copyWith(amount: dest.amount + amount));
      } else {
        // Debt: reduce currentBalance
        final debts = await ref.read(debtNotifierProvider.future);
        final dest = debts.firstWhere((d) => d.id == destinationId);
        await ref
            .read(debtNotifierProvider.notifier)
            .updateDebt(
              dest.copyWith(currentBalance: dest.currentBalance - amount),
            );
      }
    } catch (e) {
      debugPrint('Error updating destination: $e');
    }
  }

  Future<void> deleteTransfer(String transferId) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;

    // Find the transfer to reverse balances
    final transfers = await future;
    final matchingTransfers = transfers.where((t) => t.id == transferId);
    if (matchingTransfers.isEmpty) return;
    final transfer = matchingTransfers.first;

    // Reverse source asset (re-add the amount)
    try {
      final assets = await ref.read(assetNotifierProvider.future);
      final source = assets.firstWhere((a) => a.id == transfer.sourceAssetId);
      await ref
          .read(assetNotifierProvider.notifier)
          .updateAsset(
            source.copyWith(amount: source.amount + transfer.amount),
          );
    } catch (e) {
      debugPrint('Error reversing source asset on delete: $e');
    }

    // Reverse destination
    try {
      if (transfer.destinationType == TransferDestinationType.asset) {
        final assets = await ref.read(assetNotifierProvider.future);
        final dest = assets.firstWhere((a) => a.id == transfer.destinationId);
        await ref
            .read(assetNotifierProvider.notifier)
            .updateAsset(dest.copyWith(amount: dest.amount - transfer.amount));
      } else {
        // Debt: re-add to currentBalance
        final debts = await ref.read(debtNotifierProvider.future);
        final dest = debts.firstWhere((d) => d.id == transfer.destinationId);
        await ref
            .read(debtNotifierProvider.notifier)
            .updateDebt(
              dest.copyWith(
                currentBalance: dest.currentBalance + transfer.amount,
              ),
            );
      }
    } catch (e) {
      debugPrint('Error reversing destination on delete: $e');
    }

    final repo = ref.read(transferRepositoryProvider);
    await repo.deleteTransfer(groupId, transferId);
  }
}
