import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/savings_goal.dart';

class FirestoreSavingsGoalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'savings_goals';

  Stream<List<SavingsGoal>> watchSavingsGoals(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return savingsGoalFromFirestoreMap(data, doc.id);
      }).toList();
    });
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final data = savingsGoalToFirestoreMap(goal);
    await _firestore.collection(_collectionName).add(data);
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final data = savingsGoalToFirestoreMap(goal);
    await _firestore.collection(_collectionName).doc(goal.id).update(data);
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    await _firestore.collection(_collectionName).doc(goalId).delete();
  }
}

Map<String, dynamic> savingsGoalToFirestoreMap(SavingsGoal goal) {
  return {
    'groupId': goal.groupId,
    'name': goal.name,
    'icon': goal.icon,
    'currentAmount': goal.currentAmount,
    'targetAmount': goal.targetAmount,
    'color': goal.color,
    'history': goal.history.map((e) => e.toMap()).toList(),
    'isLiquid': goal.isLiquid,
  };
}

SavingsGoal savingsGoalFromFirestoreMap(
  Map<String, dynamic> data,
  String id,
) {
  return SavingsGoal(
    id: id,
    groupId: data['groupId'] as String? ?? '',
    name: data['name'] as String? ?? 'Unknown',
    icon: data['icon'] as String? ?? '💰',
    currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
    targetAmount: (data['targetAmount'] as num?)?.toDouble(),
    color: (data['color'] as int?) ?? 0xFF4CAF50,
    history: (data['history'] as List<dynamic>?)
            ?.map((e) => SavingsEntry.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    // Compatibilitat amb totes les guardioles existents.
    isLiquid: data['isLiquid'] as bool? ?? true,
  );
}
