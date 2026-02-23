import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/asset.dart';

class AssetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Asset>> getAssetsStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assets')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Asset.fromJson(doc.data())).toList();
    });
  }

  Future<void> addAsset(String groupId, Asset asset) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assets')
        .doc(asset.id)
        .set(asset.toJson());
  }

  Future<void> updateAsset(String groupId, Asset asset) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assets')
        .doc(asset.id)
        .update(asset.toJson());
  }

  Future<void> deleteAsset(String groupId, String assetId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('assets')
        .doc(assetId)
        .delete();
  }
}
