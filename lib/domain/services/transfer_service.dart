import '../models/transfer.dart';

/// Deltes nets que una alta/edició/baixa de traspàs aplica als saldos.
class TransferBalanceDeltas {
  final Map<String, double> assets;
  final Map<String, double> debts;

  const TransferBalanceDeltas({
    required this.assets,
    required this.debts,
  });
}

bool hasSameDirection({
  required double signedAmount,
  required bool existingIsIncome,
}) =>
    (signedAmount > 0) == existingIsIncome;

bool isSameBankLegIdentity({
  required String bankTxId,
  required String? bankAccountKey,
  required String oldBankTxId,
  required String? oldBankAccountKey,
}) {
  if (bankTxId != oldBankTxId) return false;
  return bankAccountKey == null ||
      oldBankAccountKey == null ||
      bankAccountKey == oldBankAccountKey;
}

/// Calcula tots els efectes abans de fer cap escriptura.
///
/// `oldTransfer` es reverteix i `newTransfer` s'aplica. Si un traspàs mou
/// diners entre dos comptes bancaris agrupats al mateix `Asset`, els dos
/// deltes es cancel·len i el mapa queda buit.
TransferBalanceDeltas calculateTransferBalanceDeltas({
  Transfer? oldTransfer,
  Transfer? newTransfer,
}) {
  final assetDeltas = <String, double>{};
  final debtDeltas = <String, double>{};

  void accumulate(Transfer transfer, int sign) {
    assetDeltas[transfer.sourceAssetId] =
        (assetDeltas[transfer.sourceAssetId] ?? 0) - sign * transfer.amount;
    if (transfer.destinationType == TransferDestinationType.asset) {
      assetDeltas[transfer.destinationId] =
          (assetDeltas[transfer.destinationId] ?? 0) + sign * transfer.amount;
    } else {
      debtDeltas[transfer.destinationId] =
          (debtDeltas[transfer.destinationId] ?? 0) - sign * transfer.amount;
    }
  }

  if (oldTransfer != null) accumulate(oldTransfer, -1);
  if (newTransfer != null) accumulate(newTransfer, 1);
  assetDeltas.removeWhere((_, delta) => delta.abs() < 0.000001);
  debtDeltas.removeWhere((_, delta) => delta.abs() < 0.000001);

  return TransferBalanceDeltas(assets: assetDeltas, debts: debtDeltas);
}

bool isBankCounterpart({
  required BankTransferLeg existing,
  required String bankAccountKey,
  required double signedAmount,
  required DateTime date,
}) {
  if (existing.bankAccountKey == bankAccountKey) return false;
  if ((existing.signedAmount > 0) == (signedAmount > 0)) return false;
  if ((existing.signedAmount.abs() - signedAmount.abs()).abs() > 0.02) {
    return false;
  }
  return existing.date.difference(date).inDays.abs() <= 3;
}

bool transferMatchesBankCounterpart({
  required Transfer transfer,
  required String bankAccountKey,
  required double signedAmount,
  required DateTime date,
  required String centimAssetId,
}) {
  if (!transfer.awaitsBankCounterpart ||
      transfer.destinationType != TransferDestinationType.asset ||
      transfer.bankLegs.length != 1) {
    return false;
  }
  if (!isBankCounterpart(
    existing: transfer.bankLegs.single,
    bankAccountKey: bankAccountKey,
    signedAmount: signedAmount,
    date: date,
  )) {
    return false;
  }
  final expectedAssetId =
      signedAmount > 0 ? transfer.destinationId : transfer.sourceAssetId;
  return expectedAssetId == centimAssetId;
}

bool conceptSuggestsInternalTransfer(String concept) {
  final normalized =
      concept.toUpperCase().replaceAll(RegExp(r'[^A-ZÀ-Ü0-9]+'), ' ').trim();
  return normalized.contains('TRASPASSOS PROPIS') ||
      normalized.contains('TRANSFER GUARDIOLA') ||
      normalized.contains('REINT CAIXER');
}
