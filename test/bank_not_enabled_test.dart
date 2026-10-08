import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centim/domain/services/bank_sync_service.dart';
import 'package:centim/l10n/app_localizations.dart';
import 'package:centim/presentation/providers/bank_consent_provider.dart';
import 'package:centim/presentation/screens/settings/bank_sync_screen.dart';

FirebaseFunctionsException _error(String code, {Object? details}) =>
    FirebaseFunctionsException(message: 'msg', code: code, details: details);

final _notEnabled = _error(
  'permission-denied',
  details: {'reason': kBankNotEnabledReason},
);

/// Servei fals: no crea cap instància de Firebase.
class _FakeBankSyncService implements BankSyncService {
  _FakeBankSyncService(this.error);
  final Object error;

  @override
  Future<BankConnectionState> listAccounts() async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpScreen(WidgetTester tester, Object error) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bankSyncServiceProvider.overrideWithValue(_FakeBankSyncService(error)),
      ],
      child: const MaterialApp(
        locale: Locale('ca'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BankSyncScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('isBankNotEnabled', () {
    test('reconeix el bloqueig pel codi i el motiu', () {
      expect(isBankNotEnabled(_notEnabled), isTrue);
    });

    test('un permission-denied sense el motiu NO és el bloqueig (p. ex. 401 del banc)', () {
      expect(isBankNotEnabled(_error('permission-denied')), isFalse);
      expect(
        isBankNotEnabled(_error('permission-denied', details: {'status': 403})),
        isFalse,
      );
    });

    test('el motiu amb un altre codi tampoc ho és', () {
      expect(
        isBankNotEnabled(
          _error('failed-precondition', details: {'reason': kBankNotEnabledReason}),
        ),
        isFalse,
      );
      expect(isBankNotEnabled(Exception('boom')), isFalse);
    });
  });

  testWidgets('pantalla del banc: grup sense accés mostra l\'avís i cap botó',
      (tester) async {
    await _pumpScreen(tester, _notEnabled);

    expect(
      find.text('La connexió bancària encara no està disponible per al teu grup.'),
      findsOneWidget,
    );
    expect(find.text('Reintenta'), findsNothing);
    expect(find.text('Connecta el banc'), findsNothing);
  });

  testWidgets('pantalla del banc: sense connexió continua oferint connectar',
      (tester) async {
    await _pumpScreen(tester, _error('failed-precondition'));

    expect(find.text('Connecta el banc'), findsOneWidget);
  });

  testWidgets('pantalla del banc: altres errors es mostren amb Reintenta',
      (tester) async {
    await _pumpScreen(tester, _error('permission-denied'));

    expect(find.text('Reintenta'), findsOneWidget);
  });

  test('el banner de caducitat no surt per a un grup sense accés', () async {
    final container = ProviderContainer(overrides: [
      bankSyncServiceProvider.overrideWithValue(_FakeBankSyncService(_notEnabled)),
    ]);
    addTearDown(container.dispose);

    expect(await container.read(bankConnectionStateProvider.future), isNull);
  });
}
