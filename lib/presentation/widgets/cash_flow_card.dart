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
      builder: (ctx) => AlertDialog(
        title: Text('Saldo inicial de ${cycle.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El pot total (comptes líquids + guardioles) amb què va obrir '
              'aquest cicle. Comprova\'l contra els saldos reals del banc '
              'abans de desar-lo.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Import',
                suffixText: '€',
                border: OutlineInputBorder(),
              ),
            ),
            if (pot != null) ...[
              const SizedBox(height: 8),
              Text(
                'De referència, el pot d\'ara mateix és ${currency.format(pot)}.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, parseEditableAmount(controller.text)),
            child: const Text('Desar'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    await ref
        .read(billingCycleRepositoryProvider)
        .setOpeningBalance(cycle.id, amount, 'manual');
    messenger.showSnackBar(
      SnackBar(content: Text('Saldo inicial de ${cycle.name} desat.')),
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

  const _AccountDetailLine({
    required this.account,
    required this.currency,
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
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
          Text(
            currency.format(account.amount),
            style: const TextStyle(fontSize: 12, color: AppTheme.anthracite),
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
