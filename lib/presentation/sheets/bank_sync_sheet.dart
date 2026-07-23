import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/asset.dart';
import '../../domain/services/bank_sync_service.dart';
import '../../domain/services/import_service.dart';
import '../providers/asset_provider.dart';
import '../screens/import/import_transactions_screen.dart';

/// El que tria l'usuari abans de baixar moviments.
class BankSyncChoice {
  final String accountKey;
  final String dateFrom; // YYYY-MM-DD
  final String? centimAssetId;

  BankSyncChoice({
    required this.accountKey,
    required this.dateFrom,
    required this.centimAssetId,
  });
}

/// Flux complet de sincronització bancària: obre el sheet de selecció i, si
/// l'usuari confirma, baixa els moviments, obre la pantalla de revisió i
/// avança lastSyncedDate quan es desa.
Future<void> runBankSyncFlow(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<BankSyncChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const BankSyncSheet(),
  );
  if (choice == null || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  BankSyncBundle bundle;
  try {
    bundle = await ref.read(importServiceProvider).syncBankAccount(
          accountKey: choice.accountKey,
          dateFrom: choice.dateFrom,
          centimAssetId: choice.centimAssetId,
        );
  } on FirebaseFunctionsException catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      final String msg;
      if (e.code == 'resource-exhausted' || e.code == 'failed-precondition') {
        // Límit de consultes PSD2 o consentiment caducat: el missatge del
        // servidor ja explica què ha de fer l'usuari.
        msg = e.message ?? 'El banc ha limitat les peticions.';
      } else {
        msg = 'Error baixant moviments: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
      );
    }
    return;
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    return;
  }

  if (context.mounted) Navigator.pop(context); // tanca el loading

  if (bundle.warnings.isNotEmpty && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(bundle.warnings.join('\n')),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  if (bundle.items.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cap moviment nou en aquest període.')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => ImportTransactionsScreen(
        transactions: bundle.items,
        initialAccountId: choice.centimAssetId,
      ),
    ),
  );

  if (saved == true) {
    try {
      final syncService = ref.read(bankSyncServiceProvider);
      for (final entry in bundle.lastDateByKey.entries) {
        await syncService.updateAccountConfig(
          accountKey: entry.key,
          lastSyncedDate: entry.value,
        );
      }
    } catch (_) {
      // No bloquejant: s'actualitzarà al proper sync.
    }
  }
}

/// Sheet de selecció: quin compte, des de quina data i on van els moviments.
/// Els valors venen precarregats de Configuració → Banc i es poden canviar
/// només per a aquesta sincronització.
class BankSyncSheet extends ConsumerStatefulWidget {
  const BankSyncSheet({super.key});

  @override
  ConsumerState<BankSyncSheet> createState() => _BankSyncSheetState();
}

class _BankSyncSheetState extends ConsumerState<BankSyncSheet> {
  bool _loading = true;
  String _error = '';
  List<BankAccountInfo> _accounts = [];
  String? _selectedKey;
  DateTime? _dateFrom;
  String? _assetId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final conn = await ref.read(bankSyncServiceProvider).listAccounts();
      if (!mounted) return;
      final enabled = conn.accounts.where((a) => a.sync).toList();
      setState(() {
        _accounts = enabled;
        _loading = false;
        if (enabled.isNotEmpty) _select(enabled.first);
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.code == 'failed-precondition'
            ? 'Cal connectar el banc primer (Configuració → Banc).'
            : (e.message ?? 'Error carregant els comptes.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Precarrega data i destí segons la config del compte triat.
  void _select(BankAccountInfo acc) {
    _selectedKey = acc.accountKey;
    final raw = acc.lastSyncedDate ?? acc.syncStartDate;
    _dateFrom = raw != null
        ? (DateTime.tryParse(raw) ??
            DateTime.now().subtract(const Duration(days: 90)))
        : DateTime.now().subtract(const Duration(days: 90));
    _assetId = acc.centimAssetId;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateFrom = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Sincronitzar banc',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.anthracite,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  Icons.account_balance,
                  size: 40,
                  color: Colors.blueGrey[400],
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error.isNotEmpty)
                _buildError(context)
              else if (_accounts.isEmpty)
                _buildNoAccounts(context)
              else
                ..._buildForm(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) => Column(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 36),
        const SizedBox(height: 12),
        Text(_error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: _load, child: const Text('Reintenta')),
      ]);

  Widget _buildNoAccounts(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No tens cap compte habilitat per sincronitzar.\n\n'
          'Ves a Configuració → Banc i activa l\'interruptor "Sincronitzar" '
          'del compte que vulguis.',
          textAlign: TextAlign.center,
        ),
      );

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
        ),
      );

  List<Widget> _buildForm(BuildContext context) {
    final assetsAsync = ref.watch(assetNotifierProvider);

    return [
      _label(context, 'Compte a sincronitzar'),
      RadioGroup<String>(
        groupValue: _selectedKey,
        onChanged: (v) {
          if (v == null) return;
          final acc = _accounts.firstWhere((a) => a.accountKey == v);
          setState(() => _select(acc));
        },
        child: Column(
          children: _accounts
              .map((a) => RadioListTile<String>(
                    value: a.accountKey,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.name ?? a.ibanMasked),
                    subtitle: Text(
                      a.lastSyncedDate != null
                          ? '${a.ibanMasked} · últim sync ${a.lastSyncedDate}'
                          : a.ibanMasked,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 16),

      _label(context, 'Sincronitzar des de'),
      InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.event),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dateFrom != null
                  ? DateFormat('dd/MM/yyyy').format(_dateFrom!)
                  : '—'),
              const Icon(Icons.edit, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'El banc sol limitar l\'històric a uns 90 dies.',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      const SizedBox(height: 16),

      _label(context, 'On van aquests moviments'),
      assetsAsync.when(
        data: (assets) {
          final liquid = assets
              .where((a) =>
                  a.type == AssetType.bankAccount || a.type == AssetType.cash)
              .toList();
          return DropdownButtonFormField<String>(
            initialValue: _assetId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
            items: [
              const DropdownMenuItem<String>(
                  value: null, child: Text('— Sense compte —')),
              ...liquid
                  .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
            ],
            onChanged: (v) => setState(() => _assetId = v),
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Text('Error carregant els actius'),
      ),
      const SizedBox(height: 24),

      FilledButton.icon(
        onPressed: (_selectedKey == null || _dateFrom == null)
            ? null
            : () => Navigator.pop(
                  context,
                  BankSyncChoice(
                    accountKey: _selectedKey!,
                    dateFrom: DateFormat('yyyy-MM-dd').format(_dateFrom!),
                    centimAssetId: _assetId,
                  ),
                ),
        icon: const Icon(Icons.download),
        label: const Text('Carregar moviments'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ];
  }
}
