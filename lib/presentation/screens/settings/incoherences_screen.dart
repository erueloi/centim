import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/incoherences_provider.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../providers/cash_flow_provider.dart';
import '../../sheets/add_transaction_sheet.dart';
import '../../../domain/services/subcategory_move_service.dart';
import 'movements_without_account_screen.dart';

/// Filtre de la pantalla: false = tot l'històric (per defecte), true = cicle actiu.
final _cycleOnlyProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Eina de manteniment (discreta): llista de moviments amb dades incoherents,
/// per corregir-los un a un. Global per defecte (tot l'històric).
class IncoherencesScreen extends ConsumerWidget {
  const IncoherencesScreen({super.key});

  String _label(String type) {
    switch (type) {
      case 'tipus':
        return 'Tipus creuat';
      case 'guardiola-creuada':
        return 'Guardiola creuada';
      default:
        return type;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'tipus':
        return Colors.orange;
      case 'guardiola-creuada':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incoherencesProvider);
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Scaffold(
      appBar: AppBar(title: const Text('Incoherències')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            // La targeta de desincronització es mostra igualment: són dues
            // comprovacions independents.
            return ListView(
              children: const [
                _MaintenanceCards(),
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 48),
                    SizedBox(height: 12),
                    Text('Cap incoherència de categoria. Tot quadra.',
                        textAlign: TextAlign.center),
                  ]),
                ),
              ],
            );
          }

          // Filtre opcional per cicle (global per defecte).
          final cycleOnly = ref.watch(_cycleOnlyProvider);
          final cycle = ref.watch(activeCycleProvider);
          final filtered = cycleOnly
              ? items.where((it) {
                  final d = it.tx.date;
                  return !d.isBefore(cycle.startDate) &&
                      !d.isAfter(cycle.endDate);
                }).toList()
              : items;

          return Column(
            children: [
              const _MaintenanceCards(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Tot l\'històric')),
                    ButtonSegment(value: true, label: Text('Cicle actual')),
                  ],
                  selected: {cycleOnly},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      ref.read(_cycleOnlyProvider.notifier).state = s.first,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.withValues(alpha: 0.08),
                child: Text(
                  '${filtered.length} moviment${filtered.length == 1 ? '' : 's'} a revisar. '
                  'Toca\'n un per corregir-lo.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Cap incoherència en aquest cicle.',
                              textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          final tx = item.tx;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _color(item.type).withValues(alpha: 0.15),
                              child: Icon(
                                tx.isIncome
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: _color(item.type),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              tx.concept.isNotEmpty
                                  ? tx.concept
                                  : '(sense concepte)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${DateFormat('dd/MM/yyyy').format(tx.date)} · '
                              '${tx.categoryName} › ${tx.subCategoryName}\n'
                              '${item.message}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currency.format(tx.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _color(item.type)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(_label(item.type),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _color(item.type))),
                                ),
                              ],
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) =>
                                    AddTransactionSheet(transactionToEdit: tx),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Les comprovacions de manteniment, totes de NOMÉS LECTURA. Són independents
/// entre si i cadascuna s'amaga si no té res a dir.
class _MaintenanceCards extends StatelessWidget {
  const _MaintenanceCards();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CycleGridCard(),
        _NoAccountCard(),
        _DesyncCard(),
      ],
    );
  }
}

/// Cicles que comparteixen dia (o que deixen dies orfes).
///
/// La convenció és que `endDate` és INCLUSIU: Juliol acaba el 30/07 i Agost
/// comença el 31/07. Si dos cicles es trepitgen, els moviments del dia
/// compartit sumen als dos alhora i la cadena de saldos inicials es trenca.
/// No es corregeix sol: Configuració › Cicles ofereix una acció explícita i
/// limitada que retalla només la data final del primer cicle.
class _CycleGridCard extends ConsumerWidget {
  const _CycleGridCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problems = ref.watch(cycleGridProblemsProvider);
    if (problems.isEmpty) return const SizedBox.shrink();

    final df = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: Colors.red.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.event_busy, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problems.length == 1
                      ? 'Hi ha un problema al calendari de cicles'
                      : 'Hi ha ${problems.length} problemes al calendari de cicles',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            for (final p in problems) ...[
              Text(p.message, style: const TextStyle(fontSize: 13)),
              Text(
                '«${p.first.name}»: ${df.format(p.first.startDate)} – '
                '${df.format(p.first.endDate)}   ·   '
                '«${p.second.name}»: ${df.format(p.second.startDate)} – '
                '${df.format(p.second.endDate)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
            ],
            const Text(
              'Resol els solapaments des de Configuració › Cicles de '
              'facturació. L’acció de manteniment conserva l’inici del segon '
              'cicle i retalla només el final del primer.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moviments sense compte assignat al cicle actiu.
class _NoAccountCard extends ConsumerWidget {
  const _NoAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(movementsWithoutAccountCountProvider);
    if (n == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: Colors.orange.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_balance_outlined,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$n moviment${n == 1 ? '' : 's'} sense compte assignat',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              'No mouen el saldo de cap actiu, així que el pot no els '
              'reflecteix i l\'estat de caixa no quadrarà.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Veure\'ls'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MovementsWithoutAccountScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Targeta de transaccions amb el pare denormalitzat desincronitzat.
///
/// NO repara res sola: informa (quantes, per què) i deixa que l'usuari revisi el
/// detall i confirmi. La reparació automàtica i silenciosa s'ha retirat
/// expressament: escriure a la base de dades sense avisar corromp dades sense
/// que te n'adonis.
class _DesyncCard extends ConsumerWidget {
  const _DesyncCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(desyncedTransactionsProvider);
    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.all(12),
          color: Colors.blue.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.sync_problem, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${items.length} moviment${items.length == 1 ? '' : 's'} '
                      'amb la categoria desincronitzada',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Apunten a una categoria que ja no conté la seva '
                  'subcategoria, segurament per una reorganització a mig fer.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Revisar i reparar'),
                    onPressed: () => _showDetail(context, ref, items),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    WidgetRef ref,
    List<DesyncedTx> items,
  ) async {
    final df = DateFormat('dd/MM/yyyy');
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reparar ${items.length} moviments?'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Es reescriuran les dades de categoria d\'aquests moviments '
                'perquè coincideixin amb el pare actual de la seva '
                'subcategoria. Els moviments sense categoria vàlida NO es '
                'toquen.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (_, i) {
                    final d = items[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${df.format(d.tx.date)} · ${d.tx.concept}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          '"${d.tx.categoryName}" → "${d.targetCategoryName}"',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reparar ${items.length}'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final n =
        await ref.read(subcategoryMoveServiceProvider).repairDesynced(items);
    messenger.showSnackBar(
      SnackBar(content: Text('$n moviments reparats.')),
    );
  }
}
