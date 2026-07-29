import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/services/bank_consent_service.dart';

void main() {
  final now = DateTime.utc(2026, 7, 29, 10);

  test('warns at seven calendar days but not at eight', () {
    expect(
      calculateBankConsentStatus(
        DateTime.utc(2026, 8, 6, 10).toIso8601String(),
        now: now,
      ).state,
      BankConsentState.valid,
    );
    final seven = calculateBankConsentStatus(
      DateTime.utc(2026, 8, 5, 10).toIso8601String(),
      now: now,
    );
    expect(seven.state, BankConsentState.expiring);
    expect(seven.daysRemaining, 7);
  });

  test('distinguishes expiry today from already expired', () {
    expect(
      calculateBankConsentStatus(
        DateTime.utc(2026, 7, 29, 18).toIso8601String(),
        now: now,
      ).state,
      BankConsentState.expiring,
    );
    expect(
      calculateBankConsentStatus(
        DateTime.utc(2026, 7, 29, 9).toIso8601String(),
        now: now,
      ).state,
      BankConsentState.expired,
    );
  });

  test('reports not connected and unknown separately', () {
    expect(
      calculateBankConsentStatus(null, connected: false).state,
      BankConsentState.notConnected,
    );
    expect(
      calculateBankConsentStatus(null).state,
      BankConsentState.unknown,
    );
  });
}
