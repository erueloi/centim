import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/asset.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';

part 'asset_provider.g.dart';

@riverpod
class AssetNotifier extends _$AssetNotifier {
  @override
  Stream<List<Asset>> build() {
    final groupIdAsync = ref.watch(currentGroupIdProvider);

    return groupIdAsync.when(
      data: (groupId) {
        if (groupId == null) return Stream.value([]);
        final repository = ref.read(assetRepositoryProvider);
        return repository.getAssetsStream(groupId).map((assets) {
          return assets;
        }).handleError((e) {
          throw e;
        });
      },
      loading: () {
        return const Stream.empty();
      },
      error: (e, s) {
        return Stream.error(e, s);
      },
    );
  }

  Future<void> addAsset(Asset asset) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');
    await ref.read(assetRepositoryProvider).addAsset(groupId, asset);
  }

  Future<void> removeAsset(String id) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');
    await ref.read(assetRepositoryProvider).deleteAsset(groupId, id);
  }

  Future<void> updateAsset(Asset asset) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No active group');
    await ref.read(assetRepositoryProvider).updateAsset(groupId, asset);
  }
}
