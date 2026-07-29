import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/transfer.dart';
import 'package:centim/domain/services/transfer_service.dart';

void main() {
  Transfer transfer({
    String source = 'a',
    String destination = 'b',
    TransferDestinationType destinationType = TransferDestinationType.asset,
    double amount = 100,
    List<BankTransferLeg> bankLegs = const [],
  }) {
    return Transfer(
      id: 't',
      groupId: 'g',
      date: DateTime(2026, 7, 20),
      amount: amount,
      sourceAssetId: source,
      sourceAssetName: source,
      destinationType: destinationType,
      destinationId: destination,
      destinationName: destination,
      bankLegs: bankLegs,
    );
  }

  test('Transfer v1 es llegeix sense migrar els documents existents', () {
    final restored = Transfer.fromJson({
      'id': 'legacy',
      'groupId': 'g',
      'date': '2026-07-20T00:00:00.000',
      'amount': 14,
      'sourceAssetId': 'a',
      'sourceAssetName': 'A',
      'destinationType': 'asset',
      'destinationId': 'b',
      'destinationName': 'B',
      'note': null,
    });

    expect(restored.source, 'manual');
    expect(restored.bankLegs, isEmpty);
    expect(restored.awaitsBankCounterpart, isFalse);
    expect(restored.schemaVersion, 1);
  });

  test('Transfer v2 serialitza les potes com a mapes Firestore', () {
    final leg = BankTransferLeg(
      bankAccountKey: 'bank-a',
      bankTxId: 'tx-1',
      signedAmount: -70,
      date: DateTime(2026, 7, 20),
      centimAssetId: 'a',
      concept: 'TRASPASSOS PROPIS',
    );
    final json = transfer(bankLegs: [leg]).toJson();

    expect(json['bankLegs'], isA<List<dynamic>>());
    expect((json['bankLegs'] as List).single, isA<Map<String, dynamic>>());
    final restored = Transfer.fromJson(json);
    expect(restored.bankLegs.single.identity, 'bank-a\u0000tx-1');
    expect(restored.bankLegs.single.signedAmount, -70);
  });

  test('actiu a actiu calcula els dos deltes abans d’escriure', () {
    final deltas = calculateTransferBalanceDeltas(
      newTransfer: transfer(amount: 70),
    );
    expect(deltas.assets, {'a': -70, 'b': 70});
    expect(deltas.debts, isEmpty);
  });

  test('dos IBAN agrupats al mateix actiu tenen delta net zero', () {
    final deltas = calculateTransferBalanceDeltas(
      newTransfer: transfer(source: 'cc', destination: 'cc', amount: 70),
    );
    expect(deltas.assets, isEmpty);
  });

  test('editar reverteix el vell i aplica el nou en un sol delta', () {
    final deltas = calculateTransferBalanceDeltas(
      oldTransfer: transfer(amount: 70),
      newTransfer: transfer(amount: 90),
    );
    expect(deltas.assets, {'a': -20, 'b': 20});
  });

  test('mateix signe és duplicat; signe oposat no ho és', () {
    expect(
      hasSameDirection(signedAmount: -70, existingIsIncome: false),
      isTrue,
    );
    expect(
      hasSameDirection(signedAmount: 70, existingIsIncome: false),
      isFalse,
    );
  });

  test('bankTxId només és exacte entre comptes nous si accountKey coincideix',
      () {
    expect(
      isSameBankLegIdentity(
        bankTxId: 'ref-1',
        bankAccountKey: 'bank-a',
        oldBankTxId: 'ref-1',
        oldBankAccountKey: 'bank-a',
      ),
      isTrue,
    );
    expect(
      isSameBankLegIdentity(
        bankTxId: 'ref-1',
        bankAccountKey: 'bank-b',
        oldBankTxId: 'ref-1',
        oldBankAccountKey: 'bank-a',
      ),
      isFalse,
    );
    expect(
      isSameBankLegIdentity(
        bankTxId: 'ref-1',
        bankAccountKey: 'bank-b',
        oldBankTxId: 'ref-1',
        oldBankAccountKey: null,
      ),
      isTrue,
    );
  });

  test('la segona pota exigeix compte real diferent, signe oposat i ±3 dies',
      () {
    final existing = BankTransferLeg(
      bankAccountKey: 'bank-a',
      bankTxId: 'tx-a',
      signedAmount: -70,
      date: DateTime(2026, 7, 20),
      centimAssetId: 'cc',
    );

    expect(
      isBankCounterpart(
        existing: existing,
        bankAccountKey: 'bank-b',
        signedAmount: 70,
        date: DateTime(2026, 7, 23),
      ),
      isTrue,
    );
    expect(
      isBankCounterpart(
        existing: existing,
        bankAccountKey: 'bank-a',
        signedAmount: 70,
        date: DateTime(2026, 7, 20),
      ),
      isFalse,
    );
    expect(
      isBankCounterpart(
        existing: existing,
        bankAccountKey: 'bank-b',
        signedAmount: -70,
        date: DateTime(2026, 7, 20),
      ),
      isFalse,
    );
  });

  test('la segona pota ha d’arribar a l’altre actiu indicat manualment', () {
    final pending = transfer(
      source: 'cc-eloi',
      destination: 'cc-jose',
      amount: 70,
      bankLegs: [
        BankTransferLeg(
          bankAccountKey: 'bank-eloi',
          bankTxId: 'tx-out',
          signedAmount: -70,
          date: DateTime(2026, 7, 20),
          centimAssetId: 'cc-eloi',
        ),
      ],
    ).copyWith(awaitsBankCounterpart: true);

    expect(
      transferMatchesBankCounterpart(
        transfer: pending,
        bankAccountKey: 'bank-jose',
        signedAmount: 70,
        date: DateTime(2026, 7, 21),
        centimAssetId: 'cc-jose',
      ),
      isTrue,
    );
    expect(
      transferMatchesBankCounterpart(
        transfer: pending,
        bankAccountKey: 'bank-third',
        signedAmount: 70,
        date: DateTime(2026, 7, 21),
        centimAssetId: 'compte-comu',
      ),
      isFalse,
    );
  });
}
