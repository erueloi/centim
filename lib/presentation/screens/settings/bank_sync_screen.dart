import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../../../ajuda/ajuda_urls.dart';
import '../../../ajuda/ancores_ajuda.dart';
import '../../../domain/services/bank_consent_service.dart';
import '../../providers/bank_consent_provider.dart';
import '../../sheets/bank_picker_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/asset.dart';
import '../../../domain/services/bank_sync_service.dart';
import '../../providers/asset_provider.dart';
import 'bank_app_wizard.dart';

enum _ConnState { loading, ready, noApp, error }

/// El grup actual no té accés a la connexió bancària: missatge informatiu,
/// sense botons de reintentar ni de connectar (no depèn de l'usuari).
class BankNotEnabledNotice extends StatelessWidget {
  final String? message;
  const BankNotEnabledNotice({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_clock_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message ?? l10n.bankNotEnabledForGroup,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const BankHelpLink(),
        ]),
      ),
    );
  }
}

/// Enllaç a la guia (`<base>/apps/centim/guia#banc-propi`).
class BankHelpLink extends StatelessWidget {
  const BankHelpLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => launchUrl(ajudaUri(AncoresAjuda.bancPropi)),
      icon: const Icon(Icons.help_outline, size: 18),
      label: Text(AppLocalizations.of(context)!.bankHelpLink),
    );
  }
}

/// Configuració de la sincronització bancària (Enable Banking): aplicació del
/// grup, connexions, comptes a sincronitzar i comptes accessibles del grup.
class BankSyncScreen extends ConsumerStatefulWidget {
  const BankSyncScreen({super.key});

  @override
  ConsumerState<BankSyncScreen> createState() => _BankSyncScreenState();
}

class _BankSyncScreenState extends ConsumerState<BankSyncScreen> {
  _ConnState _state = _ConnState.loading;
  BankSetup? _setup;
  List<BankConnectionInfo> _connections = [];
  List<BankAccountInfo> _accounts = [];
  List<GroupBankAccount> _groupAccounts = [];
  final Map<String, BankSessionInspection> _sessionInspections = {};
  final Set<String> _inspectingConnections = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _ConnState.loading);
    try {
      final service = ref.read(bankSyncServiceProvider);
      final setup = await service.getSetup();
      if (!mounted) return;
      if (!setup.configured) {
        setState(() {
          _setup = setup;
          _state = _ConnState.noApp;
        });
        return;
      }
      final conn = await service.listAccounts();
      if (!mounted) return;
      setState(() {
        _setup = setup;
        _connections = conn.connections;
        _accounts = conn.accounts;
        _groupAccounts = conn.groupAccounts;
        _state = _ConnState.ready;
      });
      ref.invalidate(bankConnectionStateProvider);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = isNoBankApp(e) ? _ConnState.noApp : _ConnState.error;
        _error = e.message ?? 'Error';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ConnState.error;
        _error = e.toString();
      });
    }
  }

  void _onSaved(BankAppSaveResult result) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.connectionsToReconnect > 0
          ? l10n.bankSavedReconnect(result.connectionsToReconnect)
          : l10n.bankSaved),
    ));
    _load();
  }

  /// Obre l'assistent complet o només el formulari de credencials.
  Future<void> _openCredentialsPage({required bool fullWizard}) async {
    final l10n = AppLocalizations.of(context)!;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          appBar: AppBar(
            title: Text(
              fullWizard ? l10n.bankSetupOwnApp : l10n.bankChangeCredentials,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (fullWizard)
                BankAppWizard(onSaved: (result) {
                  Navigator.pop(pageContext);
                  _onSaved(result);
                })
              else
                BankCredentialsForm(onSaved: (result) {
                  Navigator.pop(pageContext);
                  _onSaved(result);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCredentials() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bankDeleteConfirmTitle),
        content: Text(l10n.bankDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.bankDeleteCredentials,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(bankSyncServiceProvider).deleteAppCredentials();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.bankDeleted)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is FirebaseFunctionsException ? (e.message ?? '$e') : '$e'),
      ));
    }
  }

  Future<void> _persist(int index, BankAccountInfo updated) async {
    setState(() => _accounts[index] = updated);
    try {
      await ref.read(bankSyncServiceProvider).updateAccountConfig(
            connectionId: updated.connectionId,
            accountKey: updated.accountKey,
            sync: updated.sync,
            centimAssetId: updated.centimAssetId,
            clearCentimAssetId: updated.centimAssetId == null,
            syncStartDate: updated.syncStartDate,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No s\'ha pogut desar: $e')));
      }
    }
  }

  Future<void> _inspectSessionAccounts(String connectionId) async {
    if (_inspectingConnections.contains(connectionId)) return;
    setState(() {
      _inspectingConnections.add(connectionId);
      _sessionInspections.remove(connectionId);
    });
    try {
      final inspection = await ref
          .read(bankSyncServiceProvider)
          .inspectSessionAccounts(connectionId: connectionId);
      if (!mounted) return;
      setState(() => _sessionInspections[connectionId] = inspection);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No s’ha pogut comprovar la sessió: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _inspectingConnections.remove(connectionId));
      }
    }
  }

  /// Connexió nova: primer es tria el banc.
  Future<void> _addConnection() async {
    final aspsp = await showBankPicker(context);
    if (aspsp == null || !mounted) return;
    await _connect(
      newConnection: true,
      aspspName: aspsp.name,
      aspspCountry: aspsp.country,
    );
  }

  Future<void> _connect({
    String? connectionId,
    bool newConnection = false,
    String? aspspName,
    String? aspspCountry,
  }) async {
    if (!kIsWeb) {
      // Android/iOS (custom scheme) arriba a la propera passa de 2d.4.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('De moment la connexió es fa des de la versió web.'),
        ),
      );
      return;
    }
    try {
      // Torna a l'origen actual (web desplegada o localhost en dev).
      final redirectUrl = '${Uri.base.origin}/bank-callback';
      final start = await ref.read(bankSyncServiceProvider).startAuth(
            redirectUrl: redirectUrl,
            connectionId: connectionId,
            newConnection: newConnection,
            aspspName: aspspName,
            aspspCountry: aspspCountry,
          );
      // Redirect de tota la pestanya cap a la SCA; en tornar, /bank-callback
      // el gestiona l'app (AuthWrapper → finalizeBankSession).
      await launchUrl(
        Uri.parse(start.authUrl),
        webOnlyWindowName: '_self',
      );
    } catch (e) {
      if (isNoBankApp(e)) {
        if (mounted) setState(() => _state = _ConnState.noApp);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No s\'ha pogut iniciar la connexió: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banc / Sincronització')),
      body: switch (_state) {
        _ConnState.loading => const Center(child: CircularProgressIndicator()),
        _ConnState.error => _buildError(),
        _ConnState.noApp => _buildNoApp(),
        _ConnState.ready => _buildReady(),
      },
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintenta')),
          ]),
        ),
      );

  /// El grup no té aplicació: assistent per a l'owner, avís per a la resta.
  Widget _buildNoApp() {
    final l10n = AppLocalizations.of(context)!;
    if (_setup?.isOwner != true) {
      return BankNotEnabledNotice(message: l10n.bankNoAppMember);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.bankNoAppTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        BankAppWizard(onSaved: _onSaved),
        const Align(alignment: Alignment.centerLeft, child: BankHelpLink()),
      ],
    );
  }

  Widget _buildReady() {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_setup != null) _buildAppStatusCard(_setup!),
          const SizedBox(height: 8),
          Text(
            l10n.bankRestrictedNotice,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Align(alignment: Alignment.centerLeft, child: BankHelpLink()),
          const SizedBox(height: 8),
          const Text('Comptes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Els comptes que marquis apareixeran a la pantalla de sincronització. '
            'El compte de Cèntim i la data són valors per defecte: en cada '
            'sincronització podràs confirmar-los o canviar-los.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _addConnection,
              icon: const Icon(Icons.add_link),
              label: Text(l10n.bankAddConnection),
            ),
          ),
          const SizedBox(height: 16),
          if (_connections.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(l10n.bankNoConnections),
            ),
          for (final connection in _connections) ...[
            _buildConnectionHeader(connection),
            if (_sessionInspections[connection.connectionId]
                case final inspection?) ...[
              const SizedBox(height: 8),
              _buildSessionInspection(inspection),
            ],
            const SizedBox(height: 8),
            if (!connection.needsReconnect)
              for (int i = 0; i < _accounts.length; i++)
                if (_accounts[i].connectionId == connection.connectionId)
                  _buildAccountCard(i),
            const SizedBox(height: 12),
          ],
          _buildGroupAccounts(),
        ],
      ),
    );
  }

  Widget _buildAppStatusCard(BankSetup setup) {
    final l10n = AppLocalizations.of(context)!;
    if (setup.isLegacy) {
      return Card(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.bankAppStatusTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(l10n.bankLegacyNotice),
              if (setup.isOwner) ...[
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _openCredentialsPage(fullWizard: true),
                  icon: const Icon(Icons.settings_suggest_outlined),
                  label: Text(l10n.bankSetupOwnApp),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final env = setup.env == 'production' ? l10n.bankEnvProduction : l10n.bankEnvSandbox;
    final date = setup.validatedAt == null
        ? '—'
        : DateFormat('dd/MM/yyyy').format(setup.validatedAt!.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified_user_outlined, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  setup.appName ?? l10n.bankAppStatusTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              l10n.bankAppStatusLine(setup.appIdShort ?? '—', date, env),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            if (setup.isOwner)
              Wrap(spacing: 8, children: [
                TextButton.icon(
                  onPressed: () => _openCredentialsPage(fullWizard: false),
                  icon: const Icon(Icons.key_outlined, size: 18),
                  label: Text(l10n.bankChangeCredentials),
                ),
                TextButton.icon(
                  onPressed: _deleteCredentials,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: Text(
                    l10n.bankDeleteCredentials,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  /// "Comptes accessibles": unió dels comptes ja connectats pels membres.
  Widget _buildGroupAccounts() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(l10n.bankAccessibleAccountsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          l10n.bankAccessibleAccountsBody,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (_groupAccounts.isEmpty)
          Text(l10n.bankNoAccessibleAccounts)
        else
          for (final account in _groupAccounts)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(account.name ?? account.ibanMasked),
              // Alguns comptes (p. ex. els de prova) no tenen IBAN: sense
              // separadors buits.
              subtitle: Text([
                account.ibanMasked,
                account.aspspName,
                account.memberName ?? '',
              ].where((part) => part.isNotEmpty).join(' · ')),
            ),
      ],
    );
  }

  String _reconnectReasonText(String? reason) {
    final l10n = AppLocalizations.of(context)!;
    return switch (reason) {
      'app-removed' => l10n.bankReasonAppRemoved,
      'left-group' => l10n.bankReasonLeftGroup,
      _ => l10n.bankReasonAppChanged,
    };
  }

  Widget _buildSessionInspection(BankSessionInspection inspection) {
    final foundNew = inspection.newAccountCount > 0;
    final color = foundNew ? Colors.orange : Colors.blueGrey;
    final summary = foundNew
        ? 'La sessió veu ${inspection.liveAccountCount} comptes: '
            '${inspection.newAccountCount} encara no són a la caché de Cèntim.'
        : 'La sessió veu ${inspection.liveAccountCount} comptes, els mateixos '
            'que Cèntim té desats (${inspection.cachedAccountCount}).';

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (inspection.accounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final account in inspection.accounts)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        account.alreadyCached
                            ? Icons.check_circle_outline
                            : Icons.add_circle_outline,
                        color: account.alreadyCached ? Colors.green : color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            if (account.name?.isNotEmpty == true) account.name!,
                            account.ibanMasked,
                          ].join(' · '),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Aquesta comprovació és de només lectura i no desa cap canvi.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionHeader(BankConnectionInfo connection) {
    final status = calculateBankConsentStatus(connection.validUntil);
    final until = status.validUntil?.toLocal();
    final days = status.daysRemaining;
    final expired = status.state == BankConsentState.expired;
    final soon = status.state == BankConsentState.expiring;

    Color color = Colors.green;
    String text;
    if (connection.needsReconnect) {
      color = Colors.orange;
      text = '${AppLocalizations.of(context)!.bankNeedsReconnect}. '
          '${_reconnectReasonText(connection.reconnectReason)}';
    } else if (until == null) {
      color = Colors.grey;
      text = 'Connectada.';
    } else if (expired) {
      color = Colors.red;
      text = 'Accés caducat. Cal reconnectar.';
    } else if (soon) {
      color = Colors.orange;
      text = 'Caduca en $days dia${days == 1 ? '' : 's'} '
          '(${DateFormat('dd/MM/yyyy').format(until)}).';
    } else {
      text = 'Accés vàlid $days dies més '
          '(fins ${DateFormat('dd/MM/yyyy').format(until)}).';
    }

    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                expired || connection.needsReconnect
                    ? Icons.warning
                    : Icons.verified_user,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (connection.aspspName != null &&
                        connection.aspspName != connection.label)
                      Text(
                        connection.aspspName!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 2),
                    Text(text),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _connect(
                    connectionId: connection.connectionId,
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(expired || soon || connection.needsReconnect
                      ? AppLocalizations.of(context)!.bankReconnect
                      : 'Renova'),
                ),
                if (!connection.needsReconnect)
                  TextButton.icon(
                  onPressed:
                      _inspectingConnections.contains(connection.connectionId)
                          ? null
                          : () => _inspectSessionAccounts(
                                connection.connectionId,
                              ),
                  icon: _inspectingConnections.contains(connection.connectionId)
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search, size: 18),
                  label: const Text('Comprova comptes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(int index) {
    final acc = _accounts[index];
    final assetsAsync = ref.watch(assetNotifierProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(acc.name ?? acc.ibanMasked,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(acc.ibanMasked,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
            ),
            Switch(
              value: acc.sync,
              onChanged: (v) => _persist(index, acc.copyWith(sync: v)),
            ),
          ]),
          if (acc.sync) ...[
            const Divider(),
            // Mapatge a un actiu de Cèntim.
            assetsAsync.when(
              data: (assets) {
                final liquid = assets
                    .where((a) =>
                        a.type == AssetType.bankAccount ||
                        a.type == AssetType.cash)
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: acc.centimAssetId,
                  decoration: const InputDecoration(
                    labelText: 'Compte de Cèntim',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                        value: null, child: Text('— Sense assignar —')),
                    ...liquid.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        )),
                  ],
                  onChanged: (v) => _persist(
                      index,
                      acc.copyWith(
                          centimAssetId: v, clearCentimAssetId: v == null)),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error carregant actius'),
            ),
            const SizedBox(height: 8),
            // Data d'inici del primer sync.
            Row(children: [
              const Icon(Icons.event, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(acc.syncStartDate != null
                    ? 'Sincronitza des de ${acc.syncStartDate}'
                    : 'Sincronitza des de: (per defecte)'),
              ),
              TextButton(
                onPressed: () => _pickStartDate(index, acc),
                child: const Text('Canvia'),
              ),
            ]),
            if (acc.lastSyncedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Últim sync: ${acc.lastSyncedDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickStartDate(int index, BankAccountInfo acc) async {
    final initial = acc.syncStartDate != null
        ? DateTime.tryParse(acc.syncStartDate!) ?? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _persist(index,
          acc.copyWith(syncStartDate: DateFormat('yyyy-MM-dd').format(picked)));
    }
  }
}
