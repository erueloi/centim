import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bank_sync_service.g.dart';

/// Regió on estan desplegades les Cloud Functions (Enable Banking proxy).
const String _kFunctionsRegion = 'europe-west1';

/// Motiu (`details.reason`) que retornen les Functions bancàries quan el grup
/// actual no té accés a la connexió bancària.
const String kBankNotEnabledReason = 'bank-not-enabled';

/// Motius (`details.reason`) de les Functions bancàries de la fase 1.
const String kNoBankAppReason = 'no-bank-app';
const String kAppChangedReason = 'app-changed';
const String kNotGroupOwnerReason = 'not-group-owner';

/// Motiu (`details.reason`) d'un error de les Functions bancàries, si en té.
String? bankErrorReason(Object error) {
  if (error is! FirebaseFunctionsException) return null;
  final details = error.details;
  return details is Map ? details['reason'] as String? : null;
}

/// Cert si l'error és el bloqueig "la connexió bancària no està disponible per
/// al teu grup". No n'hi ha prou amb `permission-denied`: les Functions també
/// el fan servir per a altres casos (p. ex. un 401/403 d'Enable Banking).
bool isBankNotEnabled(Object error) {
  if (error is! FirebaseFunctionsException) return false;
  if (error.code != 'permission-denied') return false;
  return bankErrorReason(error) == kBankNotEnabledReason;
}

/// El grup no té aplicació d'Enable Banking (ni pròpia ni de transició).
bool isNoBankApp(Object error) =>
    isBankNotEnabled(error) || bankErrorReason(error) == kNoBankAppReason;

/// Estat de l'aplicació d'Enable Banking del grup (mai inclou la clau).
class BankSetup {
  final bool configured;

  /// 'group' (aplicació pròpia), 'legacy' (aplicació compartida antiga) o null.
  final String? source;
  final String? appIdShort;
  final String? env;
  final String? appName;
  final DateTime? validatedAt;
  final bool isOwner;

  const BankSetup({
    required this.configured,
    required this.source,
    required this.appIdShort,
    required this.env,
    required this.appName,
    required this.validatedAt,
    required this.isOwner,
  });

  bool get isLegacy => source == 'legacy';

  factory BankSetup.fromMap(Map<String, dynamic> map) => BankSetup(
        configured: map['configured'] as bool? ?? false,
        source: map['source'] as String?,
        appIdShort: map['appIdShort'] as String?,
        env: map['env'] as String?,
        appName: map['appName'] as String?,
        validatedAt: DateTime.tryParse(map['validatedAt'] as String? ?? ''),
        isOwner: map['isOwner'] as bool? ?? false,
      );
}

/// Resultat de desar les credencials del grup.
class BankAppSaveResult {
  final String? appIdShort;
  final String? env;
  final int connectionsKept;
  final int connectionsToReconnect;

  const BankAppSaveResult({
    required this.appIdShort,
    required this.env,
    required this.connectionsKept,
    required this.connectionsToReconnect,
  });
}

/// Un banc (ASPSP) del catàleg d'Enable Banking.
class AspspOption {
  final String name;
  final String country;
  final String? logo;
  final bool beta;

  const AspspOption({
    required this.name,
    required this.country,
    this.logo,
    this.beta = false,
  });
}

/// Compte que ja llegeix l'aplicació del grup (connexió activa d'algun membre).
class GroupBankAccount {
  final String ibanMasked;
  final String? name;
  final String aspspName;
  final String? memberName;

  const GroupBankAccount({
    required this.ibanMasked,
    required this.name,
    required this.aspspName,
    required this.memberName,
  });
}

/// Resultat de tancar l'autorització al banc.
class BankFinalizeResult {
  final int accountCount;
  final bool noLinkedAccounts;
  final String? aspspName;

  const BankFinalizeResult({
    required this.accountCount,
    required this.noLinkedAccounts,
    this.aspspName,
  });
}

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
  final String? aspspName;

  /// Creada amb una altra aplicació, eliminada o de quan l'usuari va sortir
  /// del grup: no es pot fer servir fins que es reconnecti.
  final bool needsReconnect;
  final String? reconnectReason;

  BankConnectionInfo({
    required this.connectionId,
    required this.label,
    required this.validUntil,
    required this.status,
    required this.accounts,
    this.aspspName,
    this.needsReconnect = false,
    this.reconnectReason,
  });
}

/// Estat de totes les connexions bancàries del grup.
class BankConnectionState {
  final String? validUntil;
  final List<BankConnectionInfo> connections;
  final List<BankAccountInfo> accounts;

  /// Unió dels comptes de les connexions actives de tots els membres.
  final List<GroupBankAccount> groupAccounts;

  BankConnectionState({
    required this.validUntil,
    required this.connections,
    required this.accounts,
    this.groupAccounts = const [],
  });

  factory BankConnectionState.fromMap(Map<String, dynamic> data) {
    final rawConnections = (data['connections'] as List?) ?? const [];
    final groupAccounts = ((data['groupAccounts'] as List?) ?? const [])
        .map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return GroupBankAccount(
        ibanMasked: map['ibanMasked'] as String? ?? '',
        name: map['name'] as String?,
        aspspName: map['aspspName'] as String? ?? '',
        memberName: map['memberName'] as String?,
      );
    }).toList();
    if (rawConnections.isNotEmpty || data.containsKey('groupAccounts')) {
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
          aspspName: map['aspspName'] as String?,
          needsReconnect: map['needsReconnect'] as bool? ?? false,
          reconnectReason: map['reconnectReason'] as String?,
        );
      }).toList();
      return BankConnectionState(
        validUntil: data['validUntil'] as String?,
        connections: connections,
        accounts:
            connections.expand((connection) => connection.accounts).toList(),
        groupAccounts: groupAccounts,
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

  /// Estat de l'aplicació d'Enable Banking del grup.
  Future<BankSetup> getSetup() async {
    final res = await _functions.httpsCallable('getBankSetup').call();
    return BankSetup.fromMap(Map<String, dynamic>.from(res.data as Map));
  }

  /// Només l'owner: valida (crida real a Enable Banking) i desa xifrades les
  /// credencials del grup. La clau no torna mai al client.
  Future<BankAppSaveResult> saveAppCredentials({
    required String appId,
    required String pem,
  }) async {
    final res = await _functions
        .httpsCallable('saveBankAppCredentials')
        .call({'appId': appId, 'pem': pem});
    final data = Map<String, dynamic>.from(res.data as Map);
    return BankAppSaveResult(
      appIdShort: data['appIdShort'] as String?,
      env: data['env'] as String?,
      connectionsKept: data['connectionsKept'] as int? ?? 0,
      connectionsToReconnect: data['connectionsToReconnect'] as int? ?? 0,
    );
  }

  /// Només l'owner: elimina l'aplicació del grup.
  Future<void> deleteAppCredentials() async {
    await _functions.httpsCallable('deleteBankAppCredentials').call();
  }

  /// Bancs per a particulars d'un país (amb memòria cau al servidor).
  Future<List<AspspOption>> listAspsps(String country) async {
    final res = await _functions
        .httpsCallable('listAspsps')
        .call({'country': country});
    final data = Map<String, dynamic>.from(res.data as Map);
    return ((data['aspsps'] as List?) ?? const []).map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return AspspOption(
        name: map['name'] as String? ?? '',
        country: map['country'] as String? ?? country,
        logo: map['logo'] as String?,
        beta: map['beta'] as bool? ?? false,
      );
    }).toList();
  }

  /// Inicia l'autorització AIS. Retorna la URL de SCA. `redirectUrl` permet
  /// tornar a l'origen actual (web desplegada o localhost en dev). Una
  /// connexió nova necessita el banc ([aspspName] i [aspspCountry]); una
  /// renovació, el [connectionId].
  Future<BankAuthStart> startAuth({
    String? redirectUrl,
    String? connectionId,
    bool newConnection = false,
    String? aspspName,
    String? aspspCountry,
  }) async {
    final payload = <String, dynamic>{
      if (redirectUrl != null) 'redirectUrl': redirectUrl,
      if (connectionId != null) 'connectionId': connectionId,
      if (newConnection) 'newConnection': true,
      if (aspspName != null) 'aspspName': aspspName,
      if (aspspCountry != null) 'aspspCountry': aspspCountry,
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
  Future<BankFinalizeResult> finalizeSession({
    required String code,
    required String state,
  }) async {
    final res = await _functions.httpsCallable('finalizeBankSession').call({
      'code': code,
      'state': state,
    });
    final data = Map<String, dynamic>.from((res.data as Map?) ?? const {});
    return BankFinalizeResult(
      accountCount: data['accountCount'] as int? ?? 0,
      noLinkedAccounts: data['noLinkedAccounts'] as bool? ?? false,
      aspspName: data['aspspName'] as String?,
    );
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
