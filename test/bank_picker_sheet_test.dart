import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centim/domain/services/bank_sync_service.dart';
import 'package:centim/l10n/app_localizations.dart';
import 'package:centim/presentation/sheets/bank_picker_sheet.dart';

const _es = [
  AspspOption(name: 'BBVA', country: 'ES'),
  AspspOption(name: 'Banco de Sabadell', country: 'ES'),
  AspspOption(name: 'CaixaBank', country: 'ES'),
  AspspOption(name: 'Genome', country: 'ES', beta: true),
];

class _FakeBankSyncService implements BankSyncService {
  final requested = <String>[];

  @override
  Future<List<AspspOption>> listAspsps(String country) async {
    requested.add(country);
    return country == 'ES' ? _es : const [AspspOption(name: 'Millennium', country: 'PT')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('filterAspsps: cerca sense distingir majúscules', () {
    expect(filterAspsps(_es, '').length, 4);
    expect(filterAspsps(_es, 'caixa').map((a) => a.name), ['CaixaBank']);
    expect(filterAspsps(_es, 'BANCO').map((a) => a.name), ['Banco de Sabadell']);
    expect(filterAspsps(_es, 'zzz'), isEmpty);
  });

  testWidgets('el selector carrega ES per defecte, filtra i retorna el banc triat', (tester) async {
    final service = _FakeBankSyncService();
    AspspOption? picked;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bankSyncServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          locale: const Locale('ca'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => picked = await showBankPicker(context),
                child: const Text('obre'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('obre'));
    await tester.pumpAndSettle();

    expect(service.requested, ['ES']);
    expect(find.text('CaixaBank'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'caixa');
    await tester.pumpAndSettle();
    expect(find.text('BBVA'), findsNothing);

    await tester.tap(find.text('CaixaBank'));
    await tester.pumpAndSettle();
    expect(picked?.name, 'CaixaBank');
    expect(picked?.country, 'ES');
  });
}
