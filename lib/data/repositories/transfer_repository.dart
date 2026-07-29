import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/transaction.dart' as domain;
import '../../domain/models/transfer.dart';
import '../../domain/services/transaction_effects_service.dart';
import '../../domain/services/transfer_service.dart';
import 'firestore_transaction_repository.dart';

class TransferRepository {
  final FirebaseFirestore _firestore;

  TransferRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Transfer>> getTransfersStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Transfer.fromJson(doc.data())).toList();
    });
  }

  Future<void> addTransfer(String groupId, Transfer transfer) async {
    await mutateTransfer(groupId: groupId, newTransfer: transfer);
  }

  Future<void> updateTransfer(String groupId, Transfer transfer) async {
    final old = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .doc(transfer.id)
        .get();
    if (!old.exists) throw StateError('Transfer ${transfer.id} inexistent');
    await mutateTransfer(
      groupId: groupId,
      oldTransfer: Transfer.fromJson(old.data()!),
      newTransfer: transfer,
    );
  }

  Future<void> deleteTransfer(String groupId, String transferId) async {
    final old = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .doc(transferId)
        .get();
    if (!old.exists) return;
    await mutateTransfer(
      groupId: groupId,
      oldTransfer: Transfer.fromJson(old.data()!),
    );
  }

  /// Crea, edita o esborra un traspàs i els seus efectes en UNA transacció
  /// atòmica. Tots els deltes es pleguen abans d'escriure: si origen i destí
  /// són el mateix actiu, el delta és zero i no es toca el saldo.
  Future<void> mutateTransfer({
    required String groupId,
    Transfer? oldTransfer,
    Transfer? newTransfer,
  }) async {
    if (oldTransfer == null && newTransfer == null) return;
    if (oldTransfer != null &&
        newTransfer != null &&
        oldTransfer.id != newTransfer.id) {
      throw ArgumentError('Una edició no pot canviar l’id del traspàs');
    }

    final deltas = calculateTransferBalanceDeltas(
      oldTransfer: oldTransfer,
      newTransfer: newTransfer,
    );
    final assetDeltas = deltas.assets;
    final debtDeltas = deltas.debts;

    final transfer = newTransfer ?? oldTransfer!;
    final transferRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .doc(transfer.id);

    final oldLegs = {
      for (final leg in oldTransfer?.bankLegs ?? const <BankTransferLeg>[])
        leg.identity: leg,
    };
    final newLegs = {
      for (final leg in newTransfer?.bankLegs ?? const <BankTransferLeg>[])
        leg.identity: leg,
    };

    await _firestore.runTransaction((tx) async {
      final assetRefs = {
        for (final id in assetDeltas.keys)
          id: _firestore
              .collection('groups')
              .doc(groupId)
              .collection('assets')
              .doc(id),
      };
      final debtRefs = {
        for (final id in debtDeltas.keys)
          id: _firestore
              .collection('groups')
              .doc(groupId)
              .collection('debt_accounts')
              .doc(id),
      };

      // Firestore exigeix fer totes les lectures abans de la primera escriptura.
      final assetDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in assetRefs.entries) {
        assetDocs[entry.key] = await tx.get(entry.value);
      }
      final debtDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in debtRefs.entries) {
        debtDocs[entry.key] = await tx.get(entry.value);
      }
      final bankRefDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final identity in newLegs.keys) {
        bankRefDocs[identity] = await tx.get(_bankImportRef(groupId, identity));
      }

      for (final entry in bankRefDocs.entries) {
        final existingTarget = entry.value.data()?['targetId'] as String?;
        if (entry.value.exists && existingTarget != transfer.id) {
          throw StateError('La pota bancària ja està consumida');
        }
      }

      for (final entry in assetDeltas.entries) {
        final snap = assetDocs[entry.key]!;
        if (!snap.exists) {
          throw StateError('Actiu ${entry.key} inexistent');
        }
        final current = (snap.data()!['amount'] as num).toDouble();
        tx.update(assetRefs[entry.key]!, {'amount': current + entry.value});
      }
      for (final entry in debtDeltas.entries) {
        final snap = debtDocs[entry.key]!;
        if (!snap.exists) {
          throw StateError('Deute ${entry.key} inexistent');
        }
        final current = (snap.data()!['currentBalance'] as num).toDouble();
        tx.update(
          debtRefs[entry.key]!,
          {'currentBalance': current + entry.value},
        );
      }

      if (newTransfer == null) {
        tx.delete(transferRef);
      } else {
        tx.set(transferRef, newTransfer.toJson());
      }

      for (final identity
          in oldLegs.keys.toSet().difference(newLegs.keys.toSet())) {
        tx.delete(_bankImportRef(groupId, identity));
      }
      for (final entry in newLegs.entries) {
        tx.set(_bankImportRef(groupId, entry.key), {
          'groupId': groupId,
          'bankAccountKey': entry.value.bankAccountKey,
          'bankTxId': entry.value.bankTxId,
          'targetType': 'transfer',
          'targetId': transfer.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Retorna les potes ja consumides i, si apunten a un traspàs, el seu id.
  Future<Map<String, String?>> findBankImportRefs(
    String groupId,
    Iterable<String> identities,
  ) async {
    final result = <String, String?>{};
    for (final identity in identities.toSet()) {
      final snap = await _bankImportRef(groupId, identity).get();
      if (snap.exists) {
        result[identity] = snap.data()?['targetId'] as String?;
      }
    }
    return result;
  }

  Future<List<Transfer>> getTransfersOnce(String groupId) async {
    final snap = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('transfers')
        .get();
    return snap.docs.map((doc) => Transfer.fromJson(doc.data())).toList();
  }

  Future<void> recordTransactionBankRef({
    required String groupId,
    required BankTransferLeg leg,
    required String transactionId,
  }) async {
    final ref = _bankImportRef(groupId, leg.identity);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final existingTarget = existing.data()?['targetId'] as String?;
      if (existing.exists && existingTarget != transactionId) {
        throw StateError('La pota bancària ja està consumida');
      }
      tx.set(ref, {
        'groupId': groupId,
        'bankAccountKey': leg.bankAccountKey,
        'bankTxId': leg.bankTxId,
        'targetType': 'transaction',
        'targetId': transactionId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Substitueix moviments per un traspàs (o desfà la substitució) en una sola
  /// transacció Firestore. Inclou saldos d'actiu/deute, guardioles, documents
  /// comptables i índexs bancaris.
  Future<void> replaceTransactionsAndTransfer({
    required String groupId,
    required List<Category> categories,
    List<domain.Transaction> removeTransactions = const [],
    List<domain.Transaction> addTransactions = const [],
    Transfer? oldTransfer,
    Transfer? newTransfer,
    required String auditNote,
  }) async {
    final assetDeltas = <String, double>{};
    final debtDeltas = <String, double>{};
    final goalDeltas = <String, double>{};

    void addDelta(Map<String, double> target, String id, double delta) {
      target[id] = (target[id] ?? 0) + delta;
    }

    void accumulateTransaction(domain.Transaction tx, int sign) {
      final goal = goalEffectForTransaction(tx, categories);
      if (goal != null) addDelta(goalDeltas, goal.goalId, sign * goal.delta);

      final links = linksForSubcategory(tx.subCategoryId, categories);
      if (links.debtId != null) {
        addDelta(
          debtDeltas,
          links.debtId!,
          sign * (tx.isIncome ? tx.amount : -tx.amount),
        );
      }
      if (tx.accountId != null) {
        addDelta(
          assetDeltas,
          tx.accountId!,
          sign * (tx.isIncome ? tx.amount : -tx.amount),
        );
      }
    }

    for (final tx in removeTransactions) {
      accumulateTransaction(tx, -1);
    }
    for (final tx in addTransactions) {
      accumulateTransaction(tx, 1);
    }

    final transferDeltas = calculateTransferBalanceDeltas(
      oldTransfer: oldTransfer,
      newTransfer: newTransfer,
    );
    for (final entry in transferDeltas.assets.entries) {
      addDelta(assetDeltas, entry.key, entry.value);
    }
    for (final entry in transferDeltas.debts.entries) {
      addDelta(debtDeltas, entry.key, entry.value);
    }

    assetDeltas.removeWhere((_, delta) => delta.abs() < 0.000001);
    debtDeltas.removeWhere((_, delta) => delta.abs() < 0.000001);
    goalDeltas.removeWhere((_, delta) => delta.abs() < 0.000001);

    final oldBankRefs = <String, BankTransferLeg>{};
    final newBankRefs =
        <String, ({BankTransferLeg leg, String type, String id})>{};

    BankTransferLeg? legForTransaction(domain.Transaction tx) {
      if (tx.bankAccountKey == null ||
          tx.bankAccountKey!.isEmpty ||
          tx.bankTxId == null ||
          tx.bankTxId!.isEmpty ||
          tx.accountId == null) {
        return null;
      }
      return BankTransferLeg(
        bankAccountKey: tx.bankAccountKey!,
        bankTxId: tx.bankTxId!,
        signedAmount: tx.isIncome ? tx.amount : -tx.amount,
        date: tx.date,
        centimAssetId: tx.accountId!,
        concept: tx.concept,
      );
    }

    for (final tx in removeTransactions) {
      final leg = legForTransaction(tx);
      if (leg != null) oldBankRefs[leg.identity] = leg;
    }
    for (final leg in oldTransfer?.bankLegs ?? const <BankTransferLeg>[]) {
      oldBankRefs[leg.identity] = leg;
    }
    for (final tx in addTransactions) {
      final leg = legForTransaction(tx);
      if (leg != null && tx.id != null) {
        newBankRefs[leg.identity] = (leg: leg, type: 'transaction', id: tx.id!);
      }
    }
    if (newTransfer != null) {
      for (final leg in newTransfer.bankLegs) {
        newBankRefs[leg.identity] =
            (leg: leg, type: 'transfer', id: newTransfer.id);
      }
    }

    await _firestore.runTransaction((fireTx) async {
      DocumentReference<Map<String, dynamic>> assetRef(String id) => _firestore
          .collection('groups')
          .doc(groupId)
          .collection('assets')
          .doc(id);
      DocumentReference<Map<String, dynamic>> debtRef(String id) => _firestore
          .collection('groups')
          .doc(groupId)
          .collection('debt_accounts')
          .doc(id);
      DocumentReference<Map<String, dynamic>> goalRef(String id) =>
          _firestore.collection('savings_goals').doc(id);

      final assetDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in assetDeltas.keys) {
        assetDocs[id] = await fireTx.get(assetRef(id));
      }
      final debtDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in debtDeltas.keys) {
        debtDocs[id] = await fireTx.get(debtRef(id));
      }
      final goalDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in goalDeltas.keys) {
        goalDocs[id] = await fireTx.get(goalRef(id));
      }
      final bankRefDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final identity in newBankRefs.keys) {
        bankRefDocs[identity] =
            await fireTx.get(_bankImportRef(groupId, identity));
      }

      final replaceableTargets = <String>{
        ...removeTransactions.map((tx) => tx.id).whereType<String>(),
        if (oldTransfer != null) oldTransfer.id,
      };
      for (final entry in bankRefDocs.entries) {
        final existingTarget = entry.value.data()?['targetId'] as String?;
        final desiredTarget = newBankRefs[entry.key]!.id;
        if (entry.value.exists &&
            existingTarget != desiredTarget &&
            !replaceableTargets.contains(existingTarget)) {
          throw StateError('La pota bancària ja està consumida');
        }
      }

      for (final entry in assetDeltas.entries) {
        final snap = assetDocs[entry.key]!;
        if (!snap.exists) throw StateError('Actiu ${entry.key} inexistent');
        final current = (snap.data()!['amount'] as num).toDouble();
        fireTx.update(
          assetRef(entry.key),
          {'amount': current + entry.value},
        );
      }
      for (final entry in debtDeltas.entries) {
        final snap = debtDocs[entry.key]!;
        if (!snap.exists) throw StateError('Deute ${entry.key} inexistent');
        final current = (snap.data()!['currentBalance'] as num).toDouble();
        fireTx.update(
          debtRef(entry.key),
          {'currentBalance': current + entry.value},
        );
      }
      for (final entry in goalDeltas.entries) {
        final snap = goalDocs[entry.key]!;
        if (!snap.exists) throw StateError('Guardiola ${entry.key} inexistent');
        final data = snap.data()!;
        final current = (data['currentAmount'] as num).toDouble();
        final history =
            List<dynamic>.from(data['history'] as List? ?? const []);
        history.add(
          SavingsEntry(
            date: DateTime.now(),
            amount: entry.value,
            note: auditNote,
          ).toMap(),
        );
        fireTx.update(goalRef(entry.key), {
          'currentAmount': current + entry.value,
          'history': history,
        });
      }

      for (final tx in removeTransactions) {
        if (tx.id == null) throw StateError('Moviment sense id');
        fireTx.delete(_firestore.collection('transactions').doc(tx.id));
      }
      for (final tx in addTransactions) {
        if (tx.id == null) throw StateError('Moviment sense id');
        fireTx.set(
          _firestore.collection('transactions').doc(tx.id),
          transactionToFirestoreMap(tx),
        );
      }

      if (oldTransfer != null && newTransfer == null) {
        fireTx.delete(
          _firestore
              .collection('groups')
              .doc(groupId)
              .collection('transfers')
              .doc(oldTransfer.id),
        );
      }
      if (newTransfer != null) {
        fireTx.set(
          _firestore
              .collection('groups')
              .doc(groupId)
              .collection('transfers')
              .doc(newTransfer.id),
          newTransfer.toJson(),
        );
      }

      for (final identity
          in oldBankRefs.keys.toSet().difference(newBankRefs.keys.toSet())) {
        fireTx.delete(_bankImportRef(groupId, identity));
      }
      for (final entry in newBankRefs.entries) {
        fireTx.set(_bankImportRef(groupId, entry.key), {
          'groupId': groupId,
          'bankAccountKey': entry.value.leg.bankAccountKey,
          'bankTxId': entry.value.leg.bankTxId,
          'targetType': entry.value.type,
          'targetId': entry.value.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  DocumentReference<Map<String, dynamic>> _bankImportRef(
    String groupId,
    String identity,
  ) {
    final id = base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('bank_import_refs')
        .doc(id);
  }
}
