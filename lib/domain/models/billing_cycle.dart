class BillingCycle {
  final String id;
  final String groupId;
  final String name; // e.g., "Febrer 2026"
  final DateTime startDate;
  final DateTime endDate;

  BillingCycle({
    required this.id,
    required this.groupId,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  BillingCycle copyWith({
    String? id,
    String? groupId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BillingCycle(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
