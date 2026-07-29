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
