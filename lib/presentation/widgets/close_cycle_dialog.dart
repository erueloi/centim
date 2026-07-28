import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format_utils.dart';
import '../../domain/models/asset.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/services/cash_flow_service.dart';
import '../../domain/services/cycle_integrity_service.dart';
import '../providers/asset_provider.dart';
import '../providers/cash_flow_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../screens/settings/movements_without_account_screen.dart';

/// Resultat del diàleg de tancament.
class CloseCycleDecision {
  /// Dia de cobrament: és el DIA 1 del cicle nou.
  final DateTime payday;

  /// Saldo inicial a segellar al cicle nou. `null` = tancar sense segellar-ne
  /// cap (queda en mode degradat i es pot posar més tard).
  final double? openingBalance;

  const CloseCycleDecision({
    required this.payday,
    required this.openingBalance,
  });
}

/// Confirmació abans de tancar un cicle.
///
/// El saldo inicial del cicle nou és el punt de partida de tota la cadena
/// posterior: si se segella malament, contamina tots els cicles següents i no
/// es nota fins molt més tard. Per això el diàleg ENSENYA el número desglossat,
/// el deixa editar (per quadrar-lo contra els saldos reals del banc) i permet
/// cancel·lar. Mai es segella res sol.
Future<CloseCycleDecision?> showCloseCycleDialog(
  BuildContext context,
  WidgetRef ref,
  BillingCycle cycle,
) {
  return showDialog<CloseCycleDecision>(
    context: context,
    builder: (_) => _CloseCycleDialog(cycle: cycle),
  );
}

class _CloseCycleDialog extends ConsumerStatefulWidget {
  final BillingCycle cycle;
  const _CloseCycleDialog({required this.cycle});

  @override
  ConsumerState<_CloseCycleDialog> createState() => _CloseCycleDialogState();
}

class _CloseCycleDialogState extends ConsumerState<_CloseCycleDialog> {
  late final TextEditingController _controller;
  late DateTime _payday;
  bool _initialPotLoaded = false;
  bool _seal = true;

  @override
  void initState() {
    super.initState();
    final pot = ref.read(currentPotProvider);
    _initialPotLoaded = pot != null;
    _controller = TextEditingController(
      text: pot == null ? '' : editableAmountText(pot),
    );
    _payday = DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final assetsValue = ref.watch(assetNotifierProvider).valueOrNull;
    final goalsValue = ref.watch(savingsGoalNotifierProvider).valueOrNull;
    final assets = assetsValue ?? const [];
    final goals = goalsValue ?? const [];
    final liquid = assets.where(isLiquidAsset).toList();
    final pot = assetsValue != null && goalsValue != null
        ? totalPot(assets, goals)
        : null;
    if (!_initialPotLoaded && pot != null) {
      _controller.text = editableAmountText(pot);
      _initialPotLoaded = true;
    }
    final noAccount =
        ref.watch(movementsWithoutAccountProvider(widget.cycle)).length;
    final today = DateUtils.dateOnly(DateTime.now());
    final boundary = cycleCloseBoundaryForPayday(_payday);
    final isLateClose = _payday.isBefore(today);
    final earliestPayday = DateTime(
      widget.cycle.startDate.year,
      widget.cycle.startDate.month,
      widget.cycle.startDate.day + 1,
    );
    final canClose = !earliestPayday.isAfter(today);
    final canSubmit = canClose && (!_seal || pot != null);

    return AlertDialog(
      title: Text('Tancar ${widget.cycle.name}?'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aquest és el pot que arrossegaràs al cicle nou. Comprova\'l '
                'contra els saldos reals de CaixaBank abans de segellar-lo.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Quin dia has cobrat?'),
                subtitle: Text(dateFormat.format(_payday)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: canClose
                    ? () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _payday,
                          firstDate: earliestPayday,
                          lastDate: today,
                          helpText: 'DATA DE COBRAMENT',
                        );
                        if (picked != null && mounted) {
                          setState(() => _payday = DateUtils.dateOnly(picked));
                        }
                      }
                    : null,
              ),
              Text(
                '${widget.cycle.name} acabarà el '
                '${dateFormat.format(boundary.currentEndDate)} i el cicle nou '
                'començarà el ${dateFormat.format(boundary.nextStartDate)}.',
                style: const TextStyle(fontSize: 12),
              ),

              if (isLateClose) ...[
                const SizedBox(height: 10),
                const _Info(
                  'Has triat una data anterior a avui. El desglossament de sota '
                  'és el pot registrat ara, no el que hi havia el dia del '
                  'cobrament. Revisa i ajusta el saldo abans de segellar-lo.',
                ),
              ],
              const SizedBox(height: 14),

              // ── Desglossament, per poder-lo comparar compte a compte ──
              if (pot == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                for (final a in liquid)
                  _Row(a.name, currency.format(a.amount), icon: _iconFor(a)),
                for (final g in goals)
                  _Row(g.name, currency.format(g.currentAmount), icon: g.icon),
                const Divider(height: 20),
                _Row('Pot total', currency.format(pot), bold: true),
              ],

              if (noAccount > 0) ...[
                const SizedBox(height: 14),
                _Warning(
                  text: '$noAccount moviment${noAccount == 1 ? '' : 's'} '
                      'd\'aquest cicle no ${noAccount == 1 ? 'té' : 'tenen'} '
                      'compte assignat. El pot no ${noAccount == 1 ? 'el' : 'els'} '
                      'reflecteix, així que aquesta xifra pot estar esbiaixada.',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MovementsWithoutAccountScreen(),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _seal,
                onChanged: (v) => setState(() => _seal = v ?? false),
                title: const Text('Segellar el saldo inicial del cicle nou',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text(
                  'Si el desmarques, el cicle nou queda sense saldo inicial i '
                  'el pots introduir més tard.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              if (_seal)
                TextField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial',
                    suffixText: '€',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Pots cancel·lar ara sense canviar res. Un cop confirmat, '
                'l’app encara no té una acció automàtica per desfer el '
                'tancament.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·lar'),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () {
                  final amount =
                      _seal ? parseEditableAmount(_controller.text) : null;
                  if (_seal && amount == null) {
                    return; // import invàlid: no tanquem
                  }
                  Navigator.pop(
                    context,
                    CloseCycleDecision(
                      payday: _payday,
                      openingBalance: amount,
                    ),
                  );
                }
              : null,
          child: const Text('Tancar cicle'),
        ),
      ],
    );
  }

  String _iconFor(Asset a) => a.type == AssetType.cash ? '💵' : '🏦';
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final String? icon;
  final bool bold;

  const _Row(this.label, this.value, {this.icon, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Expanded(
              child: Text(label,
                  style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String text;
  final VoidCallback onAction;

  const _Warning({required this.text, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              child: const Text('Revisar-los'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String text;

  const _Info(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
