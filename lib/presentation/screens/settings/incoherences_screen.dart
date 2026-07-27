import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/incoherences_provider.dart';
import '../../providers/billing_cycle_provider.dart';
import '../../sheets/add_transaction_sheet.dart';
import '../../../domain/services/subcategory_move_service.dart';

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
                _DesyncCard(),
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
              const _DesyncCard(),
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
