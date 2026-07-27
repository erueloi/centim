import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/category.dart';
import '../models/transaction.dart' as t_model;
import '../../data/providers/repository_providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/category_notifier.dart';
import '../../presentation/providers/transaction_notifier.dart';

part 'subcategory_move_service.g.dart';

/// Firestore accepta 500 operacions per batch; deixem marge.
const int _kBatchSize = 450;

/// Una transacció el `categoryId` de la qual apunta a una categoria que ja NO
/// conté la seva subcategoria: una reorganització (canvi de pare) a mig fer.
///
/// IMPORTANT: `categoryName` NO participa mai en la detecció. És un snapshot
/// històric — si es reanomena una categoria, els moviments antics han de
/// conservar el nom que tenia llavors. Reescriure'l seria reescriure el passat,
/// no reparar-lo. Només es reescriu com a efecte d'un canvi de pare real, on la
/// categoria de destí és una altra de debò.
class DesyncedTx {
  final t_model.Transaction tx;
  final String targetCategoryId;
  final String targetCategoryName;

  const DesyncedTx({
    required this.tx,
    required this.targetCategoryId,
    required this.targetCategoryName,
  });
}

/// Informe previ (dry-run) del canvi de categoria pare d'una subcategoria.
class SubcategoryMoveReport {
  final String subCategoryId;
  final String subCategoryName;
  final String fromName;
  final String toName;

  /// Moviments que es reclassificaran i el seu import total.
  final int transactionCount;
  final double totalAmount;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Avisos que NO bloquegen però requereixen decisió de l'usuari.
  final bool nameCollision;
  final String? linkedDebtId;
  final String? linkedSavingsGoalId;

  /// Noms dels cicles amb informe desat que quedaran obsolets.
  final List<String> staleReportCycles;

  const SubcategoryMoveReport({
    required this.subCategoryId,
    required this.subCategoryName,
    required this.fromName,
    required this.toName,
    required this.transactionCount,
    required this.totalAmount,
    required this.firstDate,
    required this.lastDate,
    required this.nameCollision,
    required this.linkedDebtId,
    required this.linkedSavingsGoalId,
    required this.staleReportCycles,
  });

  bool get hasLinks => linkedDebtId != null || linkedSavingsGoalId != null;
}

/// Mou una subcategoria de pare conservant-ne l'id, i manté consistents les
/// dades denormalitzades (categoryId/categoryName) de les transaccions.
///
/// Ordre segur:
///   1. Moviment ATÒMIC de la subcategoria (un sol batch, dos documents).
///   2. Reescriptura de les transaccions per lots (idempotent i resumible).
/// Entre 1 i 2 hi ha una finestra en què les transaccions apunten a un pare que
/// ja no conté la subcategoria; per això la UI bloqueja mentre dura i
/// `verifyAndRepair()` la tanca sola a l'arrencada si res queda a mitges.
class SubcategoryMoveService {
  final Ref ref;
  SubcategoryMoveService(this.ref);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Transaccions d'aquest grup amb la subcategoria indicada.
  ///
  /// El filtre `groupId` és OBLIGATORI a la consulta (no serveix filtrar en
  /// memòria): les regles de Firestore s'avaluen contra la consulta, i la de
  /// `transactions` exigeix isGroupMember(resource.data.groupId) → sense aquest
  /// where la consulta es rebutja amb permission-denied.
  ///
  /// Són dues igualtats: Firestore les resol amb els índexs d'un sol camp
  /// (merge join), sense necessitat d'índex compost.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _txDocs(
    String groupId,
    String subCategoryId,
  ) async {
    final snap = await _db
        .collection('transactions')
        .where('groupId', isEqualTo: groupId)
        .where('subCategoryId', isEqualTo: subCategoryId)
        .get();
    return snap.docs;
  }

  /// Calcula l'impacte del moviment SENSE escriure res. `sub` és la
  /// subcategoria tal com quedarà desada (amb les edicions aplicades), així els
  /// avisos d'enllaços reflecteixen l'estat final, no l'anterior.
  Future<SubcategoryMoveReport> dryRun({
    required Category from,
    required Category to,
    required SubCategory sub,
  }) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    final subCategoryId = sub.id;

    final docs = groupId == null ? [] : await _txDocs(groupId, subCategoryId);

    double total = 0;
    DateTime? first;
    DateTime? last;
    for (final d in docs) {
      final tx = t_model.Transaction.fromFirestore(d);
      total += tx.amount;
      if (first == null || tx.date.isBefore(first)) first = tx.date;
      if (last == null || tx.date.isAfter(last)) last = tx.date;
    }

    // Col·lisió de noms al pare destí (no bloqueja: els ids són únics).
    final collision = to.subcategories.any(
      (s) =>
          s.id != subCategoryId &&
          s.name.trim().toLowerCase() == sub.name.trim().toLowerCase(),
    );

    return SubcategoryMoveReport(
      subCategoryId: subCategoryId,
      subCategoryName: sub.name,
      fromName: from.name,
      toName: to.name,
      transactionCount: docs.length,
      totalAmount: total,
      firstDate: first,
      lastDate: last,
      nameCollision: collision,
      linkedDebtId: sub.linkedDebtId,
      linkedSavingsGoalId: sub.linkedSavingsGoalId,
      staleReportCycles:
          await _staleReports(groupId, first, last),
    );
  }

  /// Cicles amb informe desat el rang dels quals intersecta els moviments
  /// afectats: el seu desglossament per categoria quedarà obsolet.
  Future<List<String>> _staleReports(
    String? groupId,
    DateTime? first,
    DateTime? last,
  ) async {
    if (groupId == null || first == null || last == null) return [];
    try {
      final cycles = await _db
          .collection('billing_cycles')
          .where('groupId', isEqualTo: groupId)
          .get();
      final reports = await _db
          .collection('groups')
          .doc(groupId)
          .collection('cycle_reports')
          .get();
      final withReport = reports.docs.map((d) => d.id).toSet();

      final names = <String>[];
      for (final c in cycles.docs) {
        if (!withReport.contains(c.id)) continue;
        final data = c.data();
        final s = (data['startDate'] as Timestamp?)?.toDate();
        final e = (data['endDate'] as Timestamp?)?.toDate();
        if (s == null || e == null) continue;
        // Intersecció de rangs.
        if (!e.isBefore(first) && !s.isAfter(last)) {
          names.add(data['name'] as String? ?? c.id);
        }
      }
      return names;
    } catch (e) {
      debugPrint('staleReports: $e');
      return [];
    }
  }

  /// Executa el moviment. `onProgress` rep (fets, total) durant la reescriptura.
  Future<void> move({
    required Category from,
    required Category to,
    required SubCategory sub,
    void Function(int done, int total)? onProgress,
  }) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) throw Exception('No hi ha grup actiu');

    // 1. ATÒMIC: la subcategoria canvia de pare (o no canvia res).
    await ref.read(categoryRepositoryProvider).moveSubcategory(
          groupId: groupId,
          from: from,
          to: to,
          sub: sub,
        );

    // 2. Reescriptura de les dades denormalitzades de les transaccions.
    await _rewriteTransactions(
      groupId: groupId,
      subCategoryId: sub.id,
      categoryId: to.id,
      categoryName: to.name,
      onProgress: onProgress,
    );
  }

  /// Posa categoryId/categoryName al pare correcte per a totes les transaccions
  /// de la subcategoria. Idempotent: salta les que ja hi apunten.
  Future<int> _rewriteTransactions({
    required String groupId,
    required String subCategoryId,
    required String categoryId,
    required String categoryName,
    void Function(int done, int total)? onProgress,
  }) async {
    final docs = await _txDocs(groupId, subCategoryId);
    final pending = docs
        .where((d) =>
            d.data()['categoryId'] != categoryId ||
            d.data()['categoryName'] != categoryName)
        .toList();

    onProgress?.call(0, pending.length);
    var done = 0;
    for (var i = 0; i < pending.length; i += _kBatchSize) {
      final chunk = pending.skip(i).take(_kBatchSize).toList();
      final batch = _db.batch();
      for (final d in chunk) {
        batch.update(d.reference, {
          'categoryId': categoryId,
          'categoryName': categoryName,
        });
      }
      await batch.commit();
      done += chunk.length;
      onProgress?.call(done, pending.length);
    }
    return done;
  }

  /// Detecta transaccions les dades denormalitzades de les quals no quadren amb
  /// el pare actual de la seva subcategoria.
  ///
  /// NOMÉS LECTURA: no escriu mai res. La reparació és una acció explícita de
  /// l'usuari (`repairDesynced`). Cost zero en lectures: treballa sobre el que
  /// l'app ja té carregat (categoryNotifier i transactionNotifier).
  ///
  /// Les transaccions ÒRFENES (subCategoryId que no és a cap categoria) NO es
  /// retornen mai: no sabem quin hauria de ser el seu pare i no s'han de tocar.
  Future<List<DesyncedTx>> findDesynced() async {
    try {
      final categories = await ref.read(categoryNotifierProvider.future);
      if (categories.isEmpty) return [];

      // subCategoryId → pare actual (id + nom).
      final parentBySub = <String, ({String id, String name})>{};
      for (final c in categories) {
        for (final s in c.subcategories) {
          parentBySub[s.id] = (id: c.id, name: c.name);
        }
      }
      if (parentBySub.isEmpty) return [];

      final txs = await ref.read(transactionNotifierProvider.future);
      final out = <DesyncedTx>[];
      for (final t in txs) {
        if (t.id == null) continue;
        final parent = parentBySub[t.subCategoryId];
        if (parent == null) continue; // ÒRFENA: no la toquem mai.

        // NOMÉS el categoryId. El categoryName és un snapshot històric i no
        // participa en la detecció (veure DesyncedTx).
        if (t.categoryId == parent.id) continue;

        out.add(DesyncedTx(
          tx: t,
          targetCategoryId: parent.id,
          targetCategoryName: parent.name,
        ));
      }
      return out;
    } catch (e) {
      debugPrint('findDesynced: $e');
      return [];
    }
  }

  /// Repara les transaccions indicades. Acció EXPLÍCITA: només s'executa quan
  /// l'usuari ho confirma. Registra cada canvi (abans → després) al log.
  Future<int> repairDesynced(List<DesyncedTx> items) async {
    if (items.isEmpty) return 0;
    final col = _db.collection('transactions');
    var done = 0;

    for (final d in items) {
      debugPrint(
        'REPARACIÓ ${d.tx.id} "${d.tx.concept}" ${d.tx.date.toIso8601String()} '
        'sub=${d.tx.subCategoryId} | ABANS cat=${d.tx.categoryId} '
        '"${d.tx.categoryName}" → DESPRÉS cat=${d.targetCategoryId} '
        '"${d.targetCategoryName}"',
      );
    }

    for (var i = 0; i < items.length; i += _kBatchSize) {
      final chunk = items.skip(i).take(_kBatchSize).toList();
      final batch = _db.batch();
      for (final d in chunk) {
        batch.update(col.doc(d.tx.id!), {
          'categoryId': d.targetCategoryId,
          'categoryName': d.targetCategoryName,
        });
      }
      await batch.commit();
      done += chunk.length;
    }
    return done;
  }
}

@riverpod
SubcategoryMoveService subcategoryMoveService(Ref ref) =>
    SubcategoryMoveService(ref);
