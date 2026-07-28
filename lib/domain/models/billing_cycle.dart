/// Un cicle de facturació. `endDate` és INCLUSIU (Juliol acaba el 30/07 i
/// Agost comença el 31/07); vegeu `cycle_integrity_service.dart`.
class BillingCycle {
  final String id;
  final String groupId;
  final String name; // e.g., "Febrer 2026"
  final DateTime startDate;
  final DateTime endDate;

  /// Pot total (comptes líquids + guardioles) amb què obre el cicle.
  /// `null` = no registrat: la targeta de caixa treballa en mode degradat i no
  /// intenta derivar-lo de res. Mai s'escriu automàticament sense confirmació.
  final double? openingBalance;
  final DateTime? openingBalanceAt;

  /// 'manual' | 'auto-tancament'
  final String? openingBalanceSource;

  BillingCycle({
    required this.id,
    required this.groupId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.openingBalance,
    this.openingBalanceAt,
    this.openingBalanceSource,
  });

  bool get hasOpeningBalance => openingBalance != null;

  BillingCycle copyWith({
    String? id,
    String? groupId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? openingBalance,
    DateTime? openingBalanceAt,
    String? openingBalanceSource,
  }) {
    return BillingCycle(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceAt: openingBalanceAt ?? this.openingBalanceAt,
      openingBalanceSource: openingBalanceSource ?? this.openingBalanceSource,
    );
  }

  // Igualtat per VALOR. Cal perquè un `BillingCycle` s'usa com a clau de
  // `Provider.family`: amb igualtat per identitat, cada emissió del stream en
  // crea instàncies noves i la família aniria acumulant entrades que ningú
  // reaprofita ni allibera.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingCycle &&
          other.id == id &&
          other.groupId == groupId &&
          other.name == name &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.openingBalance == openingBalance &&
          other.openingBalanceAt == openingBalanceAt &&
          other.openingBalanceSource == openingBalanceSource;

  @override
  int get hashCode => Object.hash(id, groupId, name, startDate, endDate,
      openingBalance, openingBalanceAt, openingBalanceSource);
}
