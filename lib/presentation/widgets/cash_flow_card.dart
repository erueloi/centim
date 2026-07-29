import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/services/cash_flow_service.dart';
import '../providers/billing_cycle_provider.dart';
import '../providers/cash_flow_provider.dart';
import '../screens/settings/movements_without_account_screen.dart';

/// ESTAT DE CAIXA: "en quin moment estic".
///
/// És deliberadament una targeta a part del donut. El donut respon "on gasto"
/// (pressupost); això respon "quants diners hi ha". Barrejar-ho va ser l'origen
/// del malentès del "Disponible", que semblava caixa sense ser-ho.
class CashFlowCard extends ConsumerWidget {
  const CashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cashFlowStatusProvider);
    if (status == null) return const SizedBox.shrink();

    final cycle = ref.watch(activeCycleProvider);
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final noAccount = ref.watch(movementsWithoutAccountProvider(cycle)).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: AppTheme.anthracite),
                const SizedBox(width: 8),
                const Text(
                  'Estat de caixa',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.anthracite),
                ),
                const Spacer(),
                Text(cycle.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),

            // ── L'equació ──
            if (status.openingBalance != null)
              _Line(
                label: 'Saldo inicial',
                value: currency.format(status.openingBalance),
              )
            else
              const _MissingOpeningLine(),

            _Line(
              label: 'Ingressos',
              value: '+ ${currency.format(status.income)}',
              color: Colors.green.shade700,
            ),
            _Line(
              label: 'Despeses',
              value: '− ${currency.format(status.expense)}',
              color: Colors.red.shade700,
            ),
            if (status.transfersNet != 0)
              _Line(
                label: 'Traspassos',
                value: (status.transfersNet < 0 ? '− ' : '+ ') +
                    currency.format(status.transfersNet.abs()),
                color: Colors.grey[700],
              ),
            if (status.balanceAdjustments.isNotEmpty)
              _BalanceAdjustmentsBreakdown(
                status: status,
                currency: currency,
              ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),

            if (status.closingBalance != null)
              _Line(
                label: 'Saldo final',
                value: currency.format(status.closingBalance),
                bold: true,
              ),

            // La suma dels comptes és l'estat d'ARA. Ensenyar-la sota un cicle
            // passat convidaria a comparar-la amb un tancament antic, que és
            // precisament el que no vol dir res.
            if (status.comparable) ...[
              if (status.closingBalance != null) const SizedBox(height: 4),
              _RegisteredAccountsBreakdown(
                status: status,
                currency: currency,
              ),
            ],

            if (status.reconciles != null) ...[
              const SizedBox(height: 10),
              _ReconcileBanner(status: status, noAccountCount: noAccount),
            ],

            if (status.openingBalance == null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Introduir saldo inicial'),
                  onPressed: () => _askOpeningBalance(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _askOpeningBalance(BuildContext context, WidgetRef ref) async {
    final cycle = ref.read(activeCycleProvider);
    final pot = ref.read(currentPotProvider);
    final controller = TextEditingController();
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final messenger = ScaffoldMessenger.of(context);

    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _OpeningBalanceDialog(
        cycleName: cycle.name,
        controller: controller,
        currentPot: pot == null ? null : currency.format(pot),
      ),
    );
    controller.dispose();

    if (amount == null) return;
    await ref
        .read(billingCycleRepositoryProvider)
        .setOpeningBalance(cycle.id, amount, 'manual');
    messenger.showSnackBar(
      SnackBar(content: Text('Saldo inicial de ${cycle.name} desat.')),
    );
  }
}

class _OpeningBalanceDialog extends StatefulWidget {
  final String cycleName;
  final TextEditingController controller;
  final String? currentPot;

  const _OpeningBalanceDialog({
    required this.cycleName,
    required this.controller,
    required this.currentPot,
  });

  @override
  State<_OpeningBalanceDialog> createState() => _OpeningBalanceDialogState();
}

class _OpeningBalanceDialogState extends State<_OpeningBalanceDialog> {
  double? get _amount => parseEditableAmount(widget.controller.text);

  void _save() {
    final amount = _amount;
    if (amount != null) Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _amount != null;

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
              Icons.account_balance_wallet_outlined,
              color: AppTheme.anthracite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Saldo inicial de ${widget.cycleName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.anthracite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.copper.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.copper.withValues(alpha: 0.24),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: AppTheme.copper,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Introdueix el pot total amb què va obrir el cicle: '
                        'comptes líquids més guardioles disponibles. '
                        'Comprova’l contra els saldos reals del banc abans '
                        'de desar-lo.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppTheme.anthracite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.currentPot != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.anthracite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'POT ACTUAL DE REFERÈNCIA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'És el pot registrat ara, no necessàriament '
                              'el de l’inici del cicle.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.currentPot!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'SALDO AMB QUÈ VA OBRIR EL CICLE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.copper,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: widget.controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (canSave) _save();
                },
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                  hintText: '0,00',
                  suffixText: '€',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pots cancel·lar sense canviar res.',
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
        FilledButton.icon(
          onPressed: canSave ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.copper,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.lock_outline, size: 17),
          label: const Text('Desar saldo'),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _Line({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color ?? AppTheme.anthracite,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: style.copyWith(
                    color: bold ? style.color : Colors.grey[800])),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _BalanceAdjustmentsBreakdown extends StatefulWidget {
  final CashFlowStatus status;
  final NumberFormat currency;

  const _BalanceAdjustmentsBreakdown({
    required this.status,
    required this.currency,
  });

  @override
  State<_BalanceAdjustmentsBreakdown> createState() =>
      _BalanceAdjustmentsBreakdownState();
}

class _BalanceAdjustmentsBreakdownState
    extends State<_BalanceAdjustmentsBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final net = widget.status.balanceAdjustmentsNet;
    final color = Colors.blueGrey[700]!;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ajustos de saldo',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
                Text(
                  '${net < 0 ? '−' : '+'} '
                  '${widget.currency.format(net.abs())}',
                  style: TextStyle(fontSize: 14, color: color),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.expand_more, size: 18, color: color),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: !_expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                    left: 12,
                    right: 22,
                  ),
                  child: Column(
                    children: [
                      for (final adjustment in widget.status.balanceAdjustments)
                        _AccountDetailLine(
                          account: adjustment,
                          currency: widget.currency,
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Desglossament dels saldos que formen el pot actual. Col·lapsat per defecte:
/// el total continua sent una línia compacta, però es pot obrir per comparar
/// cada compte amb l'app del banc quan hi ha un descuadre.
class _RegisteredAccountsBreakdown extends StatefulWidget {
  final CashFlowStatus status;
  final NumberFormat currency;

  const _RegisteredAccountsBreakdown({
    required this.status,
    required this.currency,
  });

  @override
  State<_RegisteredAccountsBreakdown> createState() =>
      _RegisteredAccountsBreakdownState();
}

class _RegisteredAccountsBreakdownState
    extends State<_RegisteredAccountsBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final small = status.closingBalance != null;
    final bold = status.closingBalance == null;
    final color = small ? Colors.grey[700] : AppTheme.anthracite;
    final style = TextStyle(
      fontSize: small ? 12 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Suma dels comptes registrats',
                    style: style.copyWith(
                      color: bold ? style.color : Colors.grey[800],
                    ),
                  ),
                ),
                Text(
                  widget.currency.format(status.registeredAccountsTotal),
                  style: style,
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.expand_more, size: 18, color: color),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: !_expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 5, left: 12, right: 22),
                  child: Column(
                    children: [
                      for (final account in status.liquidAccounts)
                        _AccountDetailLine(
                          account: account,
                          currency: widget.currency,
                        ),
                      if (status.savingsAccounts.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(child: Divider(height: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Guardioles',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(height: 1)),
                            ],
                          ),
                        ),
                        for (final account in status.savingsAccounts)
                          _AccountDetailLine(
                            account: account,
                            currency: widget.currency,
                          ),
                      ],
                      if (status.nonLiquidSavingsAccounts.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(child: Divider(height: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'No líquides · fora del pot',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(height: 1)),
                            ],
                          ),
                        ),
                        for (final account in status.nonLiquidSavingsAccounts)
                          _AccountDetailLine(
                            account: account,
                            currency: widget.currency,
                            muted: true,
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _AccountDetailLine extends StatelessWidget {
  final RegisteredAccountBalance account;
  final NumberFormat currency;
  final bool muted;

  const _AccountDetailLine({
    required this.account,
    required this.currency,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              account.name,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                color: muted ? Colors.grey[500] : Colors.grey[800],
              ),
            ),
          ),
          Text(
            currency.format(account.amount),
            style: TextStyle(
              fontSize: 12,
              color: muted ? Colors.grey[500] : AppTheme.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode degradat: hi ha cicles (els històrics) sense saldo inicial registrat.
/// No se'n dedueix cap: encadenar-lo cap enrere exigiria que tot l'històric fos
/// net, i sabem que no ho és.
class _MissingOpeningLine extends StatelessWidget {
  const _MissingOpeningLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text('Saldo inicial',
                style: TextStyle(fontSize: 14, color: Colors.grey[800])),
          ),
          Text('no registrat',
              style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ReconcileBanner extends StatelessWidget {
  final CashFlowStatus status;
  final int noAccountCount;

  const _ReconcileBanner({required this.status, required this.noAccountCount});

  @override
  Widget build(BuildContext context) {
    final ok = status.reconciles == true;
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final color = ok ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok
                      ? 'Quadra amb els comptes registrats.'
                      : 'Descuadre de ${currency.format(status.difference!.abs())}.',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color.shade800),
                ),
              ),
            ],
          ),
          if (!ok && noAccountCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$noAccountCount moviment${noAccountCount == 1 ? '' : 's'} '
              'd\'aquest cicle no ${noAccountCount == 1 ? 'té' : 'tenen'} '
              'cap compte assignat, i això no mou el saldo de cap actiu.',
              style: const TextStyle(fontSize: 12),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MovementsWithoutAccountScreen()),
                ),
                child: const Text('Veure\'ls'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
