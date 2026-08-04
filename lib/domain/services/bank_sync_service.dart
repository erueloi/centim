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
  final String connectionId;
  final String? validUntil;

  BankAuthStart({
    required this.authUrl,
    required this.aspspName,
    required this.connectionId,
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
  final String connectionId;
  final String accountKey; // clau estable (identification_hash)
  final String ibanMasked;
  final String? name;
  final String? currency;
  final List<BankMovement> transactions;
  final String? warning; // p.ex. límit d'històric del banc

  BankAccountData({
    required this.connectionId,
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
  final String connectionId;
  final String connectionLabel;
  final String accountKey;
  final String ibanMasked;
  final String? name;
  final String? currency;
  final bool sync;
  final String? centimAssetId;
  final String? syncStartDate;
  final String? lastSyncedDate;

  BankAccountInfo({
    required this.connectionId,
    required this.connectionLabel,
    required this.accountKey,
    required this.ibanMasked,
    required this.name,
    required this.currency,
    required this.sync,
    required this.centimAssetId,
    required this.syncStartDate,
    required this.lastSyncedDate,
  });

  String get selectionKey => '$connectionId::$accountKey';

  BankAccountInfo copyWith({
    bool? sync,
    String? centimAssetId,
    bool clearCentimAssetId = false,
    String? syncStartDate,
  }) {
    return BankAccountInfo(
      connectionId: connectionId,
      connectionLabel: connectionLabel,
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

class BankConnectionInfo {
  final String connectionId;
  final String label;
  final String? validUntil;
  final String status;
  final List<BankAccountInfo> accounts;

  BankConnectionInfo({
    required this.connectionId,
    required this.label,
    required this.validUntil,
    required this.status,
    required this.accounts,
  });
}

/// Estat de totes les connexions bancàries del grup.
class BankConnectionState {
  final String? validUntil;
  final List<BankConnectionInfo> connections;
  final List<BankAccountInfo> accounts;

  BankConnectionState({
    required this.validUntil,
    required this.connections,
    required this.accounts,
  });

  factory BankConnectionState.fromMap(Map<String, dynamic> data) {
    final rawConnections = (data['connections'] as List?) ?? const [];
    if (rawConnections.isNotEmpty) {
      final connections = rawConnections.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final connectionId = map['connectionId'] as String? ?? '';
        final label = map['label'] as String? ?? 'CaixaBank';
        final accounts = ((map['accounts'] as List?) ?? const [])
            .map((account) => _bankAccountInfoFromMap(
                  Map<String, dynamic>.from(account as Map),
                  fallbackConnectionId: connectionId,
                  fallbackConnectionLabel: label,
                ))
            .toList();
        return BankConnectionInfo(
          connectionId: connectionId,
          label: label,
          validUntil: map['validUntil'] as String?,
          status: map['status'] as String? ?? 'connected',
          accounts: accounts,
        );
      }).toList();
      return BankConnectionState(
        validUntil: data['validUntil'] as String?,
        connections: connections,
        accounts:
            connections.expand((connection) => connection.accounts).toList(),
      );
    }

    // Compatibilitat amb una Function antiga durant desplegaments escalonats.
    final accounts = ((data['accounts'] as List?) ?? const [])
        .map((account) => _bankAccountInfoFromMap(
              Map<String, dynamic>.from(account as Map),
              fallbackConnectionId: 'caixabank',
              fallbackConnectionLabel: 'CaixaBank',
            ))
        .toList();
    final connection = BankConnectionInfo(
      connectionId: 'caixabank',
      label: 'CaixaBank',
      validUntil: data['validUntil'] as String?,
      status: 'connected',
      accounts: accounts,
    );
    return BankConnectionState(
      validUntil: data['validUntil'] as String?,
      connections: [connection],
      accounts: accounts,
    );
  }
}

BankAccountInfo _bankAccountInfoFromMap(
  Map<String, dynamic> map, {
  required String fallbackConnectionId,
  required String fallbackConnectionLabel,
}) =>
    BankAccountInfo(
      connectionId: map['connectionId'] as String? ?? fallbackConnectionId,
      connectionLabel:
          map['connectionLabel'] as String? ?? fallbackConnectionLabel,
      accountKey: map['accountKey'] as String? ?? '',
      ibanMasked: map['ibanMasked'] as String? ?? '',
      name: map['name'] as String?,
      currency: map['currency'] as String?,
      sync: map['sync'] as bool? ?? false,
      centimAssetId: map['centimAssetId'] as String?,
      syncStartDate: map['syncStartDate'] as String?,
      lastSyncedDate: map['lastSyncedDate'] as String?,
    );

/// Compte que la sessió actual d'Enable Banking retorna en una comprovació
/// directa. Només inclou metadades segures per mostrar a la UI.
class BankSessionAccountPreview {
  final String ibanMasked;
  final String? name;
  final String? currency;
  final bool alreadyCached;

  BankSessionAccountPreview({
    required this.ibanMasked,
    required this.name,
    required this.currency,
    required this.alreadyCached,
  });
}

/// Resultat de comparar la sessió viva amb la caché actual de Cèntim.
class BankSessionInspection {
  final String connectionId;
  final int cachedAccountCount;
  final int liveAccountCount;
  final List<BankSessionAccountPreview> accounts;

  BankSessionInspection({
    required this.connectionId,
    required this.cachedAccountCount,
    required this.liveAccountCount,
    required this.accounts,
  });

  int get newAccountCount => accounts.where((a) => !a.alreadyCached).length;
}

/// Petició de sync d'un compte concret (clau + data d'inici incremental).
class BankAccountRequest {
  final String key;
  final String? connectionId;
  final String? dateFrom;
  BankAccountRequest({
    required this.key,
    this.connectionId,
    this.dateFrom,
  });

  Map<String, dynamic> toMap() => {
        'key': key,
        if (connectionId != null) 'connectionId': connectionId,
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
  Future<BankAuthStart> startAuth({
    String? redirectUrl,
    String? connectionId,
    bool newConnection = false,
  }) async {
    final payload = <String, dynamic>{
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
      if (connectionId != null) 'connectionId': connectionId,
      if (newConnection) 'newConnection': true,
    };
    final res = await _functions
        .httpsCallable('startBankAuth')
        .call(payload.isEmpty ? null : payload);
    final data = Map<String, dynamic>.from(res.data as Map);
    return BankAuthStart(
      authUrl: data['authUrl'] as String,
      aspspName: data['aspspName'] as String? ?? '',
      connectionId: data['connectionId'] as String? ?? 'caixabank',
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
    String? connectionId,
    bool? sync,
    String? centimAssetId,
    bool clearCentimAssetId = false,
    String? syncStartDate,
    String? lastSyncedDate,
  }) async {
    final payload = <String, dynamic>{
      'accountKey': accountKey,
      if (connectionId != null) 'connectionId': connectionId,
    };
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
    return BankConnectionState.fromMap(data);
  }

  /// Consulta en directe els comptes visibles per la sessió actual. És una
  /// prova de només lectura: no substitueix la sessió ni actualitza la caché.
  Future<BankSessionInspection> inspectSessionAccounts({
    required String connectionId,
  }) async {
    final res = await _functions
        .httpsCallable('inspectBankSessionAccounts')
        .call({'connectionId': connectionId});
    final data = Map<String, dynamic>.from(res.data as Map);
    final accounts = ((data['accounts'] as List?) ?? []).map((a) {
      final account = Map<String, dynamic>.from(a as Map);
      return BankSessionAccountPreview(
        ibanMasked: account['ibanMasked'] as String? ?? '',
        name: account['name'] as String?,
        currency: account['currency'] as String?,
        alreadyCached: account['alreadyCached'] as bool? ?? false,
      );
    }).toList();
    return BankSessionInspection(
      connectionId: data['connectionId'] as String? ?? connectionId,
      cachedAccountCount: data['cachedAccountCount'] as int? ?? 0,
      liveAccountCount: data['liveAccountCount'] as int? ?? accounts.length,
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
        connectionId: am['connectionId'] as String? ?? '',
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
