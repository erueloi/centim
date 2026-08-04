import 'package:centim/domain/services/bank_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la resposta legacy continua sent una connexió CaixaBank vàlida', () {
    final state = BankConnectionState.fromMap({
      'validUntil': '2026-10-21T00:00:00Z',
      'accounts': [
        {
          'accountKey': 'eloi-1717',
          'ibanMasked': 'ES****1717',
          'name': 'Eloi',
          'sync': true,
          'centimAssetId': 'cc-principal',
        },
      ],
    });

    expect(state.connections, hasLength(1));
    expect(state.connections.single.connectionId, 'caixabank');
    expect(state.accounts.single.connectionId, 'caixabank');
    expect(state.accounts.single.centimAssetId, 'cc-principal');
  });

  test('dues sessions es fusionen en quatre comptes sense perdre la ruta', () {
    final state = BankConnectionState.fromMap({
      'validUntil': '2026-10-21T00:00:00Z',
      'connections': [
        _connection(
          id: 'caixabank',
          label: 'Eloi',
          accountKeys: ['eloi-1717', 'eloi-9071'],
        ),
        _connection(
          id: 'caixabank-jose',
          label: 'Jose',
          accountKeys: ['jose-2607', 'jose-5934'],
        ),
      ],
    });

    expect(state.connections, hasLength(2));
    expect(state.accounts, hasLength(4));
    expect(
      state.accounts
          .where((account) => account.connectionId == 'caixabank-jose')
          .map((account) => account.accountKey),
      ['jose-2607', 'jose-5934'],
    );
    expect(
      state.accounts.map((account) => account.selectionKey).toSet(),
      hasLength(4),
    );
  });

  test('la petició de sync inclou la sessió propietària del compte', () {
    final request = BankAccountRequest(
      key: 'jose-2607',
      connectionId: 'caixabank-jose',
      dateFrom: '2026-07-01',
    );

    expect(request.toMap(), {
      'key': 'jose-2607',
      'connectionId': 'caixabank-jose',
      'dateFrom': '2026-07-01',
    });
  });
}

Map<String, dynamic> _connection({
  required String id,
  required String label,
  required List<String> accountKeys,
}) =>
    {
      'connectionId': id,
      'label': label,
      'validUntil': '2026-10-21T00:00:00Z',
      'status': 'connected',
      'accounts': [
        for (final key in accountKeys)
          {
            'connectionId': id,
            'connectionLabel': label,
            'accountKey': key,
            'ibanMasked': 'ES****${key.substring(key.length - 4)}',
            'name': label,
            'sync': true,
          },
      ],
    };
