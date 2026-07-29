import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format_utils.dart';
import '../../core/theme/app_theme.dart';
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
    final potBreakdown = assetsValue != null && goalsValue != null
        ? buildCashPotBreakdown(assets, goals)
        : null;
    final pot = potBreakdown?.total;
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.copper.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: AppTheme.anthracite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tancar ${widget.cycle.name}?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.anthracite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BankCheckNotice(
                'Aquest és el pot que arrossegaràs al cicle nou. Comprova’l '
                'contra els saldos reals de CaixaBank abans de segellar-lo.',
              ),
              const SizedBox(height: 16),

              _PaydayCard(
                payday: dateFormat.format(_payday),
                boundaryText: '${widget.cycle.name} acabarà el '
                    '${dateFormat.format(boundary.currentEndDate)} · el cicle '
                    'nou començarà el '
                    '${dateFormat.format(boundary.nextStartDate)}',
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

              if (isLateClose) ...[
                const SizedBox(height: 12),
                const _Info(
                  'Has triat una data anterior a avui. El desglossament de sota '
                  'és el pot registrat ara, no el que hi havia el dia del '
                  'cobrament. Revisa i ajusta el saldo abans de segellar-lo.',
                ),
              ],
              const SizedBox(height: 18),

              // ── Desglossament, per poder-lo comparar compte a compte ──
              if (potBreakdown == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                const _SectionLabel('Comptes líquids'),
                for (final account in potBreakdown.liquidAccounts)
                  _BalanceRow(
                    account.name,
                    currency.format(account.amount),
                    icon: '🏦',
                  ),
                if (potBreakdown.liquidSavings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const _SectionLabel('Guardioles disponibles'),
                  for (final goal in potBreakdown.liquidSavings)
                    _BalanceRow(
                      goal.name,
                      currency.format(goal.amount),
                      icon: '🐷',
                    ),
                ],
                if (potBreakdown.nonLiquidSavings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const _SectionLabel(
                    'No disponibles immediatament',
                    muted: true,
                  ),
                  for (final goal in potBreakdown.nonLiquidSavings)
                    _BalanceRow(
                      goal.name,
                      currency.format(goal.amount),
                      icon: '🔒',
                      note: 'Fora del pot',
                      muted: true,
                    ),
                ],
                const SizedBox(height: 14),
                _PotTotalCard(amount: currency.format(pot)),
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
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.sand.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                  activeColor: AppTheme.copper,
                  checkColor: Colors.white,
                  value: _seal,
                  onChanged: (v) => setState(() => _seal = v ?? false),
                  title: const Text(
                    'Segellar el saldo inicial del cicle nou',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.anthracite,
                    ),
                  ),
                  subtitle: const Text(
                    'Si el desmarques, el podràs introduir més tard.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              if (_seal) ...[
                const SizedBox(height: 12),
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
              ],
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
          style: TextButton.styleFrom(foregroundColor: AppTheme.anthracite),
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
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.copper,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Tancar cicle'),
        ),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final String? icon;
  final String? note;
  final bool muted;

  const _BalanceRow(
    this.label,
    this.value, {
    this.icon,
    this.note,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                color: muted ? Colors.grey[600] : AppTheme.anthracite,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: muted ? Colors.grey[600] : AppTheme.anthracite,
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool muted;

  const _SectionLabel(this.text, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: muted ? Colors.grey[500] : AppTheme.copper,
        ),
      ),
    );
  }
}

class _PotTotalCard extends StatelessWidget {
  final String amount;

  const _PotTotalCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.anthracite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'POT DISPONIBLE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaydayCard extends StatelessWidget {
  final String payday;
  final String boundaryText;
  final VoidCallback? onTap;

  const _PaydayCard({
    required this.payday,
    required this.boundaryText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.sand.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppTheme.copper,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATA DE COBRAMENT',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.copper,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payday,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.anthracite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      boundaryText,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.anthracite),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankCheckNotice extends StatelessWidget {
  final String text;

  const _BankCheckNotice(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.copper.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.copper.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 18,
            color: AppTheme.copper,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppTheme.anthracite,
              ),
            ),
          ),
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
