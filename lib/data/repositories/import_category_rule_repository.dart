import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/import_category_rule.dart';

class ImportCategoryRuleRepository {
  final FirebaseFirestore _firestore;

  ImportCategoryRuleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _rules(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('import_rules');

  Stream<List<ImportCategoryRule>> watchRules(String groupId) {
    return _rules(groupId)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
              (doc) => ImportCategoryRule.fromFirestore(doc.data(), doc.id),
            )
            .toList(growable: false));
  }

  Future<List<ImportCategoryRule>> getRulesOnce(String groupId) async {
    final snapshot =
        await _rules(groupId).orderBy('priority', descending: true).get();
    return snapshot.docs
        .map((doc) => ImportCategoryRule.fromFirestore(doc.data(), doc.id))
        .toList(growable: false);
  }

  Future<void> saveRule(ImportCategoryRule rule) async {
    final ref = rule.id.isEmpty
        ? _rules(rule.groupId).doc()
        : _rules(rule.groupId).doc(rule.id);
    await ref.set(rule.copyWith(id: ref.id).toFirestore());
  }

  Future<void> deleteRule(String groupId, String ruleId) =>
      _rules(groupId).doc(ruleId).delete();
}
