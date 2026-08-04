import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/bank_consent_service.dart';
import '../../domain/services/bank_sync_service.dart';

final bankConnectionStateProvider =
    FutureProvider<BankConnectionState?>((ref) async {
  try {
    return await ref.watch(bankSyncServiceProvider).listAccounts();
  } on FirebaseFunctionsException catch (error) {
    if (error.code == 'failed-precondition') return null;
    rethrow;
  }
});

final bankConsentClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(hours: 1),
    (_) => DateTime.now(),
  );
});

final bankConsentStatusProvider =
    Provider<AsyncValue<BankConsentStatus>>((ref) {
  final now = ref.watch(bankConsentClockProvider).valueOrNull ?? DateTime.now();
  return ref.watch(bankConnectionStateProvider).whenData(
        (connection) => calculateBankConsentStatus(
          connection?.validUntil,
          now: now,
          connected: connection != null,
        ),
      );
});

class BankConsentAlert {
  final BankConnectionInfo connection;
  final BankConsentStatus status;

  const BankConsentAlert({
    required this.connection,
    required this.status,
  });
}

/// Connexió que necessita atenció amb més urgència. Una sessió caducada no
/// bloqueja ni amaga les altres connexions encara vàlides.
final bankConsentAlertProvider = Provider<AsyncValue<BankConsentAlert?>>((ref) {
  final now = ref.watch(bankConsentClockProvider).valueOrNull ?? DateTime.now();
  return ref.watch(bankConnectionStateProvider).whenData((state) {
    if (state == null) return null;
    final alerts = state.connections
        .map((connection) => BankConsentAlert(
              connection: connection,
              status: calculateBankConsentStatus(
                connection.validUntil,
                now: now,
              ),
            ))
        .where((alert) => alert.status.needsAttention)
        .toList()
      ..sort((a, b) {
        final aExpired = a.status.state == BankConsentState.expired;
        final bExpired = b.status.state == BankConsentState.expired;
        if (aExpired != bExpired) return aExpired ? -1 : 1;
        return (a.status.daysRemaining ?? 9999)
            .compareTo(b.status.daysRemaining ?? 9999);
      });
    return alerts.firstOrNull;
  });
});
