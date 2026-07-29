enum BankConsentState { notConnected, unknown, valid, expiring, expired }

class BankConsentStatus {
  final BankConsentState state;
  final DateTime? validUntil;
  final int? daysRemaining;

  const BankConsentStatus({
    required this.state,
    this.validUntil,
    this.daysRemaining,
  });

  bool get needsAttention =>
      state == BankConsentState.expiring || state == BankConsentState.expired;
}

BankConsentStatus calculateBankConsentStatus(
  String? validUntil, {
  DateTime? now,
  bool connected = true,
}) {
  if (!connected) {
    return const BankConsentStatus(state: BankConsentState.notConnected);
  }
  final until = validUntil == null ? null : DateTime.tryParse(validUntil);
  if (until == null) {
    return const BankConsentStatus(state: BankConsentState.unknown);
  }
  final current = now ?? DateTime.now();
  final localUntil = until.toLocal();
  final currentDay = DateTime(current.year, current.month, current.day);
  final untilDay = DateTime(localUntil.year, localUntil.month, localUntil.day);
  final days = untilDay.difference(currentDay).inDays;
  if (until.isBefore(current.toUtc())) {
    return BankConsentStatus(
      state: BankConsentState.expired,
      validUntil: until,
      daysRemaining: days,
    );
  }
  return BankConsentStatus(
    state: days <= 7 ? BankConsentState.expiring : BankConsentState.valid,
    validUntil: until,
    daysRemaining: days,
  );
}
