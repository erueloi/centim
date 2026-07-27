import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../domain/services/ledger_service.dart';
import '../../domain/services/subcategory_move_service.dart';
import 'transaction_notifier.dart';
import 'category_notifier.dart';

/// Transaccions amb el pare denormalitzat desincronitzat. NOMÉS LECTURA: la
/// reparació sempre l'ha de confirmar l'usuari.
final desyncedTransactionsProvider =
    FutureProvider<List<DesyncedTx>>((ref) async {
  // Depèn dels mateixos streams, així es refresca sol després de reparar.
  ref.watch(transactionNotifierProvider);
  ref.watch(categoryNotifierProvider);
  return ref.read(subcategoryMoveServiceProvider).findDesynced();
});

/// Un moviment marcat com a incoherent, amb el motiu, per a la pantalla de
/// manteniment. Escaneja TOT l'històric (no un cicle): és una eina per netejar.
class IncoherenceItem {
  final Transaction tx;
  final String type; // 'tipus' | 'guardiola-creuada'
  final String message;

  IncoherenceItem({required this.tx, required this.type, required this.message});
}

/// Llista d'incoherències sobre tot l'històric, ordenada per data descendent.
final incoherencesProvider = FutureProvider<List<IncoherenceItem>>((ref) async {
  final txs = await ref.watch(transactionNotifierProvider.future);
  final categories = await ref.watch(categoryNotifierProvider.future);
  final look = LedgerLookups.from(categories);

  final items = <IncoherenceItem>[];
  for (final tx in txs) {
    final c = classifyTransaction(tx, look);
    for (final inc in c.incoherences) {
      items.add(IncoherenceItem(tx: tx, type: inc.type, message: inc.message));
    }
  }

  items.sort((a, b) => b.tx.date.compareTo(a.tx.date));
  return items;
});
