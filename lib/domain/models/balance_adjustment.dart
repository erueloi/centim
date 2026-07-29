import 'package:cloud_firestore/cloud_firestore.dart';

enum BalanceAdjustmentType { adjustment, reversal }

class BalanceAdjustment {
  final String id;
  final String groupId;
  final String savingsGoalId;
  final String savingsGoalName;
  final DateTime date;
  final double amount;
  final String? reason;
  final bool affectsPot;
  final BalanceAdjustmentType type;
  final String? reversesAdjustmentId;

  const BalanceAdjustment({
    required this.id,
    required this.groupId,
    required this.savingsGoalId,
    required this.savingsGoalName,
    required this.date,
    required this.amount,
    required this.reason,
    required this.affectsPot,
    required this.type,
    this.reversesAdjustmentId,
  });

  bool get isReversal => type == BalanceAdjustmentType.reversal;

  Map<String, dynamic> toFirestore() => {
        'groupId': groupId,
        'savingsGoalId': savingsGoalId,
        'savingsGoalName': savingsGoalName,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'reason': reason,
        'affectsPot': affectsPot,
        'type': type.name,
        'reversesAdjustmentId': reversesAdjustmentId,
      };

  factory BalanceAdjustment.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    final rawDate = data['date'];
    return BalanceAdjustment(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      savingsGoalId: data['savingsGoalId'] as String? ?? '',
      savingsGoalName: data['savingsGoalName'] as String? ?? 'Guardiola',
      date: rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.tryParse(rawDate as String? ?? '') ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      reason: data['reason'] as String?,
      affectsPot: data['affectsPot'] as bool? ?? true,
      type: BalanceAdjustmentType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => BalanceAdjustmentType.adjustment,
      ),
      reversesAdjustmentId: data['reversesAdjustmentId'] as String?,
    );
  }
}

Set<String> reversedAdjustmentIds(Iterable<BalanceAdjustment> adjustments) =>
    adjustments
        .where((item) => item.isReversal)
        .map((item) => item.reversesAdjustmentId)
        .whereType<String>()
        .toSet();

int effectiveAdjustmentCount(
  Iterable<BalanceAdjustment> adjustments, {
  required DateTime since,
  String? savingsGoalId,
}) {
  final reversed = reversedAdjustmentIds(adjustments);
  return adjustments.where((item) {
    return !item.isReversal &&
        !reversed.contains(item.id) &&
        !item.date.isBefore(since) &&
        (savingsGoalId == null || item.savingsGoalId == savingsGoalId);
  }).length;
}
