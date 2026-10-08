import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centim/l10n/app_localizations.dart';

import '../../domain/services/bank_sync_service.dart';

/// Països on Enable Banking té bancs (ES per defecte).
const List<String> kBankCountries = [
  'ES', 'AT', 'BE', 'BG', 'CY', 'DE', 'DK', 'EE', 'FI', 'FR', 'GR', 'HR', //
  'HU', 'IE', 'IS', 'IT', 'LI', 'LT', 'LU', 'LV', 'MT', 'NL', 'NO', 'PL',
  'PT', 'RO', 'SE', 'SI', 'SK',
];

/// Bancs que coincideixen amb la cerca (sense distingir majúscules).
List<AspspOption> filterAspsps(List<AspspOption> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((a) => a.name.toLowerCase().contains(q)).toList();
}

/// Obre el selector de banc. Retorna el banc triat, o null si es tanca.
Future<AspspOption?> showBankPicker(BuildContext context) {
  return showModalBottomSheet<AspspOption>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const BankPickerSheet(),
  );
}

class BankPickerSheet extends ConsumerStatefulWidget {
  const BankPickerSheet({super.key});

  @override
  ConsumerState<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends ConsumerState<BankPickerSheet> {
  String _country = 'ES';
  String _query = '';
  final Map<String, List<AspspOption>> _byCountry = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final country = _country;
    if (_byCountry.containsKey(country)) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final aspsps = await ref.read(bankSyncServiceProvider).listAspsps(country);
      if (!mounted) return;
      setState(() {
        _byCountry[country] = aspsps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = filterAspsps(_byCountry[_country] ?? const [], _query);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.bankPickTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    initialValue: _country,
                    decoration: InputDecoration(
                      labelText: l10n.bankPickCountry,
                      isDense: true,
                    ),
                    items: [
                      for (final c in kBankCountries)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (c) {
                      if (c == null) return;
                      setState(() => _country = c);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: l10n.bankPickSearch,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, textAlign: TextAlign.center))
                      : visible.isEmpty
                          ? Center(child: Text(l10n.bankPickEmpty))
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (context, i) {
                                final aspsp = visible[i];
                                return ListTile(
                                  leading: _BankLogo(url: aspsp.logo),
                                  title: Text(aspsp.name),
                                  trailing: aspsp.beta
                                      ? Chip(
                                          label: Text(l10n.bankPickBeta),
                                          visualDensity: VisualDensity.compact,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(context, aspsp),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  final String? url;
  const _BankLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.account_balance, color: Colors.grey);
    final logo = url;
    if (logo == null || logo.isEmpty) return fallback;
    return SizedBox(
      width: 32,
      height: 32,
      child: Image.network(
        logo,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
