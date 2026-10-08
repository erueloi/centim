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

final _phase0Blocked = _error(
  'permission-denied',
  details: {'reason': kBankNotEnabledReason},
);
final _noApp = _error('failed-precondition', details: {'reason': kNoBankAppReason});

const _ownerNoApp = BankSetup(
  configured: false,
  source: null,
  appIdShort: null,
  env: null,
  appName: null,
  validatedAt: null,
  isOwner: true,
);

BankSetup _configured({bool isOwner = false, String source = 'group'}) => BankSetup(
      configured: true,
      source: source,
      appIdShort: '6f374fe4…',
      env: 'production',
      appName: 'Cèntim Llar',
      validatedAt: DateTime.utc(2026, 10, 8),
      isOwner: isOwner,
    );

/// Servei fals: no crea cap instància de Firebase.
class _FakeBankSyncService implements BankSyncService {
  _FakeBankSyncService({this.setup, this.setupError, this.state, this.listError});
  final BankSetup? setup;
  final Object? setupError;
  final BankConnectionState? state;
  final Object? listError;

  @override
  Future<BankSetup> getSetup() async {
    if (setupError != null) throw setupError!;
    return setup!;
  }

  @override
  Future<BankConnectionState> listAccounts() async {
    if (listError != null) throw listError!;
    return state!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpScreen(WidgetTester tester, _FakeBankSyncService service) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bankSyncServiceProvider.overrideWithValue(service)],
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
  group('motius d\'error', () {
    test('el bloqueig de la fase 0 i el grup sense aplicació són "sense app"', () {
      expect(isNoBankApp(_phase0Blocked), isTrue);
      expect(isNoBankApp(_noApp), isTrue);
    });

    test('un permission-denied sense motiu NO és cap d\'aquests (p. ex. 401 del banc)', () {
      expect(isBankNotEnabled(_error('permission-denied')), isFalse);
      expect(isNoBankApp(_error('permission-denied', details: {'status': 403})), isFalse);
      expect(isNoBankApp(Exception('boom')), isFalse);
    });

    test('bankErrorReason llegeix el motiu', () {
      expect(bankErrorReason(_noApp), kNoBankAppReason);
      expect(bankErrorReason(_error('internal')), isNull);
    });
  });

  testWidgets('sense aplicació, un membre veu que ho ha de demanar a l\'owner', (tester) async {
    await _pumpScreen(
      tester,
      _FakeBankSyncService(setup: _ownerNoApp.copyAsMember()),
    );
    expect(
      find.text('Demana a l\'owner del grup que configuri la connexió bancària.'),
      findsOneWidget,
    );
    expect(find.text('Crea l\'aplicació a Enable Banking'), findsNothing);
    expect(find.text('Com configurar la connexió bancària'), findsOneWidget);
  });

  testWidgets('sense aplicació, l\'owner veu l\'assistent amb els valors per copiar', (tester) async {
    await _pumpScreen(tester, _FakeBankSyncService(setup: _ownerNoApp));
    expect(find.text('Crea l\'aplicació a Enable Banking'), findsOneWidget);
    expect(find.text('Enllaça els comptes'), findsOneWidget);
    expect(find.text('Enganxa l\'id i la clau'), findsOneWidget);
    expect(find.text('https://centim-162bd.web.app/bank-callback'), findsOneWidget);
    expect(find.text('https://centim-162bd.web.app/privacy'), findsOneWidget);
    expect(find.text('https://centim-162bd.web.app/terms'), findsOneWidget);
    expect(find.byTooltip('Copia'), findsNWidgets(4));
  });

  testWidgets('functions antigues (bloqueig de la fase 0): avís sense botons', (tester) async {
    await _pumpScreen(tester, _FakeBankSyncService(setupError: _phase0Blocked));
    expect(find.text('Reintenta'), findsNothing);
    expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
  });

  testWidgets('amb aplicació: estat, avís del mode restringit i comptes accessibles', (tester) async {
    await _pumpScreen(
      tester,
      _FakeBankSyncService(
        setup: _configured(),
        state: BankConnectionState(
          validUntil: null,
          connections: const [],
          accounts: const [],
          groupAccounts: const [
            GroupBankAccount(
              ibanMasked: 'ES****1717',
              name: 'Compte comú',
              aspspName: 'CaixaBank',
              memberName: 'Eloi',
            ),
            // Compte de prova sense IBAN (com els de Mock ASPSP).
            GroupBankAccount(
              ibanMasked: '',
              name: 'Akseli Hämäläinen',
              aspspName: 'Mock ASPSP',
              memberName: 'proba@centim.eloi',
            ),
          ],
        ),
      ),
    );
    expect(find.text('Cèntim Llar'), findsOneWidget);
    expect(find.textContaining('6f374fe4…'), findsOneWidget);
    expect(find.textContaining('Producció'), findsOneWidget);
    // Un membre no veu les accions de l'owner.
    expect(find.text('Canvia les credencials'), findsNothing);
    expect(
      find.text('Només es poden llegir els comptes enllaçats al panell d\'Enable Banking del grup.'),
      findsOneWidget,
    );
    expect(find.text('Encara no has connectat cap banc.'), findsOneWidget);
    expect(find.text('Afegeix una connexió'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Comptes accessibles'), 200);
    expect(find.textContaining('No és la llista del panell'), findsOneWidget);
    expect(find.text('ES****1717 · CaixaBank · Eloi'), findsOneWidget);
    expect(find.text('Mock ASPSP · proba@centim.eloi'), findsOneWidget);
  });

  testWidgets('l\'owner veu Canvia les credencials i Elimina', (tester) async {
    await _pumpScreen(
      tester,
      _FakeBankSyncService(
        setup: _configured(isOwner: true),
        state: BankConnectionState(validUntil: null, connections: const [], accounts: const []),
      ),
    );
    expect(find.text('Canvia les credencials'), findsOneWidget);
    expect(find.text('Elimina'), findsOneWidget);
  });

  testWidgets('aplicació compartida antiga: l\'owner pot configurar la del grup', (tester) async {
    await _pumpScreen(
      tester,
      _FakeBankSyncService(
        setup: _configured(isOwner: true, source: 'legacy'),
        state: BankConnectionState(validUntil: null, connections: const [], accounts: const []),
      ),
    );
    expect(find.textContaining('aplicació compartida antiga'), findsOneWidget);
    expect(find.text('Configura l\'aplicació del grup'), findsOneWidget);
  });

  testWidgets('una connexió d\'una altra aplicació diu "Cal reconnectar" i per què', (tester) async {
    await _pumpScreen(
      tester,
      _FakeBankSyncService(
        setup: _configured(),
        state: BankConnectionState(
          validUntil: null,
          accounts: const [],
          connections: [
            BankConnectionInfo(
              connectionId: 'bbva-1',
              label: 'Compte BBVA',
              aspspName: 'BBVA',
              validUntil: null,
              status: 'needs-reconnect',
              accounts: const [],
              needsReconnect: true,
              reconnectReason: kAppChangedReason,
            ),
          ],
        ),
      ),
    );
    expect(find.textContaining('Cal reconnectar'), findsOneWidget);
    expect(find.textContaining('S\'ha canviat l\'aplicació'), findsOneWidget);
    expect(find.text('Reconnecta'), findsOneWidget);
    expect(find.text('Comprova comptes'), findsNothing);
  });

  testWidgets('altres errors es mostren amb Reintenta', (tester) async {
    await _pumpScreen(tester, _FakeBankSyncService(setupError: _error('internal')));
    expect(find.text('Reintenta'), findsOneWidget);
  });

  test('el banner de caducitat no surt per a un grup sense aplicació', () async {
    for (final error in [_noApp, _phase0Blocked]) {
      final container = ProviderContainer(overrides: [
        bankSyncServiceProvider.overrideWithValue(_FakeBankSyncService(listError: error)),
      ]);
      addTearDown(container.dispose);
      expect(await container.read(bankConnectionStateProvider.future), isNull);
    }
  });
}

extension on BankSetup {
  BankSetup copyAsMember() => BankSetup(
        configured: configured,
        source: source,
        appIdShort: appIdShort,
        env: env,
        appName: appName,
        validatedAt: validatedAt,
        isOwner: false,
      );
}
