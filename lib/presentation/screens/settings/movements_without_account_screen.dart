import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/billing_cycle_provider.dart';
import '../../providers/cash_flow_provider.dart';
import '../../sheets/add_transaction_sheet.dart';

/// Àmbit de la llista: true = cicle actiu (per defecte), false = tot l'històric.
final _cycleOnlyProvider = StateProvider.autoDispose<bool>((ref) => true);

/// Moviments que mouen diners reals sense cap compte assignat.
///
/// Sense `accountId` el saldo de l'actiu no es mou i el pot queda descuadrat
/// exactament per aquest import. NO es repara res automàticament: assignar un
/// compte canvia saldos, i això ho ha de decidir l'usuari moviment a moviment.
class MovementsWithoutAccountScreen extends ConsumerWidget {
  const MovementsWithoutAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleOnly = ref.watch(_cycleOnlyProvider);
    final cycle = ref.watch(activeCycleProvider);
    final items =
        ref.watch(movementsWithoutAccountProvider(cycleOnly ? cycle : null));
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Scaffold(
      appBar: AppBar(title: const Text('Moviments sense compte')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(cycle.name)),
                const ButtonSegment(value: false, label: Text('Tot l\'històric')),
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
              items.isEmpty
                  ? 'Tots els moviments tenen compte assignat.'
                  : '${items.length} moviment${items.length == 1 ? '' : 's'} '
                      'sense compte. No mouen el saldo de cap actiu, així que el '
                      'pot no els reflecteix. Toca\'n un per assignar-li compte.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (!cycleOnly)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Nota: la importació d\'Excel no ha assignat mai compte, de '
                'manera que a l\'històric complet això és el comportament '
                'esperat, no una anomalia.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 48),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final tx = items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.orange.withValues(alpha: 0.15),
                          child: Icon(
                            tx.isIncome
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.orange,
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
                          '${tx.categoryName} › ${tx.subCategoryName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          currency.format(tx.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) =>
                              AddTransactionSheet(transactionToEdit: tx),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
