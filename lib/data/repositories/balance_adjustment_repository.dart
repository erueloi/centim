import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/balance_adjustment.dart';
import '../../domain/models/savings_goal.dart';

class BalanceAdjustmentRepository {
  final FirebaseFirestore _firestore;

  BalanceAdjustmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _adjustments(String groupId) =>
      _firestore
          .collection('groups')
          .doc(groupId)
          .collection('balance_adjustments');

  DocumentReference<Map<String, dynamic>> _goal(String goalId) =>
      _firestore.collection('savings_goals').doc(goalId);

  Stream<List<BalanceAdjustment>> watchAdjustments(String groupId) {
    return _adjustments(groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BalanceAdjustment.fromFirestore(doc.data(), doc.id))
            .toList(growable: false));
  }

  Future<void> adjustSavingsGoalBalance({
    required String groupId,
    required String goalId,
    required double newAmount,
    String? reason,
  }) async {
    final adjustmentRef = _adjustments(groupId).doc();
    final goalRef = _goal(goalId);
    final date = DateTime.now();
    final normalizedReason =
        reason == null || reason.trim().isEmpty ? null : reason.trim();

    await _firestore.runTransaction((transaction) async {
      final goalSnapshot = await transaction.get(goalRef);
      if (!goalSnapshot.exists) {
        throw StateError('La guardiola ja no existeix');
      }
      final data = goalSnapshot.data()!;
      if (data['groupId'] != groupId) {
        throw StateError('La guardiola no pertany al grup actiu');
      }

      final current = (data['currentAmount'] as num?)?.toDouble() ?? 0;
      final delta = newAmount - current;
      if (delta.abs() < 0.000001) return;

      final goalName = data['name'] as String? ?? 'Guardiola';
      final affectsPot = data['isLiquid'] as bool? ?? true;
      final adjustment = BalanceAdjustment(
        id: adjustmentRef.id,
        groupId: groupId,
        savingsGoalId: goalId,
        savingsGoalName: goalName,
        date: date,
        amount: delta,
        reason: normalizedReason,
        affectsPot: affectsPot,
        type: BalanceAdjustmentType.adjustment,
      );
      final history =
          List<dynamic>.from(data['history'] as List? ?? const <dynamic>[]);
      history.add(
        SavingsEntry(
          date: date,
          amount: delta,
          note: normalizedReason ?? 'Ajust de saldo',
          type: SavingsEntryType.adjustment,
          adjustmentId: adjustment.id,
        ).toMap(),
      );

      transaction.update(goalRef, {
        'currentAmount': newAmount,
        'history': history,
      });
      transaction.set(adjustmentRef, adjustment.toFirestore());
    });
  }

  Future<void> reverseAdjustment(BalanceAdjustment original) async {
    if (original.isReversal) {
      throw StateError('Una reversió no es pot tornar a revertir');
    }
    final reversalRef =
        _adjustments(original.groupId).doc('reversal_${original.id}');
    final originalRef = _adjustments(original.groupId).doc(original.id);
    final goalRef = _goal(original.savingsGoalId);
    final date = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final originalSnapshot = await transaction.get(originalRef);
      final reversalSnapshot = await transaction.get(reversalRef);
      final goalSnapshot = await transaction.get(goalRef);
      if (!originalSnapshot.exists || !goalSnapshot.exists) {
        throw StateError('L’ajust o la guardiola ja no existeixen');
      }
      if (reversalSnapshot.exists) {
        throw StateError('Aquest ajust ja està revertit');
      }

      final stored = BalanceAdjustment.fromFirestore(
        originalSnapshot.data()!,
        originalSnapshot.id,
      );
      if (stored.isReversal) {
        throw StateError('L’entrada seleccionada ja és una reversió');
      }

      final goalData = goalSnapshot.data()!;
      final current = (goalData['currentAmount'] as num?)?.toDouble() ?? 0;
      final reversal = BalanceAdjustment(
        id: reversalRef.id,
        groupId: stored.groupId,
        savingsGoalId: stored.savingsGoalId,
        savingsGoalName: stored.savingsGoalName,
        date: date,
        amount: -stored.amount,
        reason: 'Reversió de l’ajust del saldo',
        affectsPot: stored.affectsPot,
        type: BalanceAdjustmentType.reversal,
        reversesAdjustmentId: stored.id,
      );
      final history = List<dynamic>.from(
        goalData['history'] as List? ?? const <dynamic>[],
      );
      history.add(
        SavingsEntry(
          date: date,
          amount: reversal.amount,
          note: reversal.reason!,
          type: SavingsEntryType.reversal,
          adjustmentId: reversal.id,
          reversesAdjustmentId: stored.id,
        ).toMap(),
      );

      transaction.update(goalRef, {
        'currentAmount': current + reversal.amount,
        'history': history,
      });
      transaction.set(reversalRef, reversal.toFirestore());
    });
  }
}
