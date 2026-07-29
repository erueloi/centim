import 'package:cloud_firestore/cloud_firestore.dart';

enum SavingsEntryType { movement, adjustment, reversal }

class SavingsEntry {
  final DateTime date;
  final double amount;
  final String note;
  final SavingsEntryType type;
  final String? adjustmentId;
  final String? reversesAdjustmentId;

  SavingsEntry({
    required this.date,
    required this.amount,
    required this.note,
    this.type = SavingsEntryType.movement,
    this.adjustmentId,
    this.reversesAdjustmentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'note': note,
      'type': type.name,
      'adjustmentId': adjustmentId,
      'reversesAdjustmentId': reversesAdjustmentId,
    };
  }

  factory SavingsEntry.fromMap(Map<String, dynamic> map) {
    return SavingsEntry(
      date: (map['date'] as Timestamp).toDate(),
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String? ?? '',
      type: SavingsEntryType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => SavingsEntryType.movement,
      ),
      adjustmentId: map['adjustmentId'] as String?,
      reversesAdjustmentId: map['reversesAdjustmentId'] as String?,
    );
  }
}

class SavingsGoal {
  final String id;
  final String groupId;
  final String name;
  final String icon; // Emoji or IconData code
  final double currentAmount;
  final double? targetAmount; // Null if it's an open-ended fund
  final int color; // Color value (int)
  final List<SavingsEntry> history;
  final bool isLiquid;

  SavingsGoal({
    required this.id,
    required this.groupId,
    required this.name,
    required this.icon,
    required this.currentAmount,
    this.targetAmount,
    required this.color,
    required this.history,
    this.isLiquid = true,
  });

  SavingsGoal copyWith({
    String? id,
    String? groupId,
    String? name,
    String? icon,
    double? currentAmount,
    double? targetAmount,
    int? color,
    List<SavingsEntry>? history,
    bool? isLiquid,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      color: color ?? this.color,
      history: history ?? this.history,
      isLiquid: isLiquid ?? this.isLiquid,
    );
  }
}
