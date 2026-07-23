import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bank_sync_service.g.dart';

/// Regió on estan desplegades les Cloud Functions (Enable Banking proxy).
const String _kFunctionsRegion = 'europe-west1';

/// Resultat de startBankAuth: URL a què cal portar l'usuari per fer la SCA.
class BankAuthStart {
  final String authUrl;
  final String aspspName;
  final String? validUntil;

  BankAuthStart({
    required this.authUrl,
    required this.aspspName,
    this.validUntil,
  });
}

/// Un moviment bancari ja normalitzat pel servidor.
class BankMovement {
  final String? bankTxId;
  final DateTime date;
  final String dateString;
  final double amount; // amb signe: + ingrés, - despesa
  final String? currency;
  final String concept;
  final bool isIncome;

  BankMovement({
    required this.bankTxId,
    required this.date,
    required this.dateString,
    required this.amount,
    required this.currency,
    required this.concept,
    required this.isIncome,
  });
}

/// Dades d'un compte retornades per fetchBankTransactions.
class BankAccountData {
  final String accountKey; // clau estable (identification_hash)
  final String ibanMasked;
  final String? name;
  final String? currency;
  final List<BankMovement> transactions;
  final String? warning; // p.ex. límit d'històric del banc

  BankAccountData({
    required this.accountKey,
    required this.ibanMasked,
    required this.name,
    required this.currency,
    required this.transactions,
    this.warning,
  });
}

/// Info d'un compte linked per al selector (listBankAccounts), amb la config
/// de sync desada per l'usuari.
class BankAccountInfo {
  final String accountKey;
  final String ibanMasked;
  final String? name;
  final String? currency;
  final bool sync;
  final String? centimAssetId;
  final String? syncStartDate;
  final String? lastSyncedDate;

  BankAccountInfo({
    required this.accountKey,
    required this.ibanMasked,
    required this.name,
    required this.currency,
    required this.sync,
    required this.centimAssetId,
    required this.syncStartDate,
    required this.lastSyncedDate,
  });

  BankAccountInfo copyWith({
    bool? sync,
    String? centimAssetId,
    bool clearCentimAssetId = false,
    String? syncStartDate,
  }) {
    return BankAccountInfo(
      accountKey: accountKey,
      ibanMasked: ibanMasked,
      name: name,
      currency: currency,
      sync: sync ?? this.sync,
      centimAssetId:
          clearCentimAssetId ? null : (centimAssetId ?? this.centimAssetId),
      syncStartDate: syncStartDate ?? this.syncStartDate,
      lastSyncedDate: lastSyncedDate,
    );
  }
}

/// Estat de la connexió bancària + comptes (resultat de listBankAccounts).
class BankConnectionState {
  final String? validUntil;
  final List<BankAccountInfo> accounts;
  BankConnectionState({required this.validUntil, required this.accounts});
}

/// Petició de sync d'un compte concret (clau + data d'inici incremental).
class BankAccountRequest {
  final String key;
  final String? dateFrom;
  BankAccountRequest({required this.key, this.dateFrom});

  Map<String, dynamic> toMap() => {
        'key': key,
        if (dateFrom != null) 'dateFrom': dateFrom,
      };
}

/// Resposta completa de fetchBankTransactions.
class BankFetchResult {
  final String env;
  final List<BankAccountData> accounts;

  BankFetchResult({required this.env, required this.accounts});

  /// Tots els moviments de tots els comptes, aplanats.
  List<BankMovement> get allMovements =>
      accounts.expand((a) => a.transactions).toList();
}

/// Client de les Cloud Functions d'Enable Banking. Mai parla directament amb
/// Enable Banking ni toca la clau privada: tot passa per les nostres Functions.
class BankSyncService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _kFunctionsRegion);

  /// Inicia l'autorització AIS. Retorna la URL de SCA. `redirectUrl` permet
  /// tornar a l'origen actual (web desplegada o localhost en dev).
  Future<BankAuthStart> startAuth({String? redirectUrl}) async {
    final res = await _functions.httpsCallable('startBankAuth').call(
          redirectUrl != null ? {'redirectUrl': redirectUrl} : null,
        );
    final data = Map<String, dynamic>.from(res.data as Map);
    return BankAuthStart(
      authUrl: data['authUrl'] as String,
      aspspName: data['aspspName'] as String? ?? '',
      validUntil: data['validUntil'] as String?,
    );
  }

  /// Tanca la sessió bescanviant el code de la SCA (i validant el state).
  Future<void> finalizeSession({
    required String code,
    required String state,
  }) async {
    await _functions.httpsCallable('finalizeBankSession').call({
      'code': code,
      'state': state,
    });
  }

  /// Desa/actualitza la config de sync d'un compte (via Cloud Function, Admin SDK).
  Future<void> updateAccountConfig({
    required String accountKey,
    bool? sync,
    String? centimAssetId,
    bool clearCentimAssetId = false,
    String? syncStartDate,
    String? lastSyncedDate,
  }) async {
    final payload = <String, dynamic>{'accountKey': accountKey};
    if (sync != null) payload['sync'] = sync;
    if (clearCentimAssetId) {
      payload['centimAssetId'] = null;
    } else if (centimAssetId != null) {
      payload['centimAssetId'] = centimAssetId;
    }
    if (syncStartDate != null) payload['syncStartDate'] = syncStartDate;
    if (lastSyncedDate != null) payload['lastSyncedDate'] = lastSyncedDate;
    await _functions.httpsCallable('updateBankAccountConfig').call(payload);
  }

  /// Llista els comptes linked (per al selector) + estat de connexió.
  Future<BankConnectionState> listAccounts() async {
    final res = await _functions.httpsCallable('listBankAccounts').call();
    final data = Map<String, dynamic>.from(res.data as Map);
    final accounts = ((data['accounts'] as List?) ?? []).map((a) {
      final am = Map<String, dynamic>.from(a as Map);
      return BankAccountInfo(
        accountKey: am['accountKey'] as String? ?? '',
        ibanMasked: am['ibanMasked'] as String? ?? '',
        name: am['name'] as String?,
        currency: am['currency'] as String?,
        sync: am['sync'] as bool? ?? false,
        centimAssetId: am['centimAssetId'] as String?,
        syncStartDate: am['syncStartDate'] as String?,
        lastSyncedDate: am['lastSyncedDate'] as String?,
      );
    }).toList();
    return BankConnectionState(
      validUntil: data['validUntil'] as String?,
      accounts: accounts,
    );
  }

  /// Descarrega moviments i saldos normalitzats. Si es passen `accounts`,
  /// baixa només aquests comptes amb el seu `dateFrom` (incremental).
  Future<BankFetchResult> fetchTransactions({
    List<BankAccountRequest>? accounts,
    String? ibanSuffix,
    String? dateFrom,
    String? dateTo,
  }) async {
    final payload = <String, dynamic>{};
    if (accounts != null && accounts.isNotEmpty) {
      payload['accounts'] = accounts.map((a) => a.toMap()).toList();
    }
    if (ibanSuffix != null) payload['ibanSuffix'] = ibanSuffix;
    if (dateFrom != null) payload['dateFrom'] = dateFrom;
    if (dateTo != null) payload['dateTo'] = dateTo;

    final res = await _functions
        .httpsCallable('fetchBankTransactions')
        .call(payload.isEmpty ? null : payload);
    final data = Map<String, dynamic>.from(res.data as Map);

    final accountsOut = ((data['accounts'] as List?) ?? []).map((a) {
      final am = Map<String, dynamic>.from(a as Map);
      final txs = ((am['transactions'] as List?) ?? []).map((t) {
        final tm = Map<String, dynamic>.from(t as Map);
        final ds = tm['date'] as String?;
        return BankMovement(
          bankTxId: tm['bankTxId'] as String?,
          date: ds != null ? DateTime.parse(ds) : DateTime.now(),
          dateString: ds ?? '',
          amount: (tm['amount'] as num).toDouble(),
          currency: tm['currency'] as String?,
          concept: tm['concept'] as String? ?? '',
          isIncome: tm['isIncome'] as bool? ?? false,
        );
      }).toList();
      return BankAccountData(
        accountKey: am['accountKey'] as String? ?? '',
        ibanMasked: am['ibanMasked'] as String? ?? '',
        name: am['name'] as String?,
        currency: am['currency'] as String?,
        transactions: txs,
        warning: am['warning'] as String?,
      );
    }).toList();

    return BankFetchResult(
      env: data['env'] as String? ?? '',
      accounts: accountsOut,
    );
  }
}

@riverpod
BankSyncService bankSyncService(Ref ref) => BankSyncService();
