import '../models/transaction.dart';
import '../models/category.dart';

/// Font ÚNICA de veritat per classificar i sumar moviments. Dashboard, trends,
/// cycle_reports i budget han de consumir això; cap pantalla ha de tornar a
/// sumar pel seu compte.
///
/// Regles canòniques (acordades):
///  - EXCLUSIÓ: un moviment amb `savingsGoalId != null` o subcategoria amb
///    `linkedSavingsGoalId` NO suma als totals d'ingrés/despesa; va a
///    saved/withdrawn (mateixa regla que ja feia el Dashboard).
///  - El SIGNE el mana `isIncome`, no `category.type`.
///  - Taula híbrida asimètrica per direcció oposada:
///      · categoria despesa + isIncome=true  → REFUND: resta del gastat (sense flag)
///      · categoria ingrés  + isIncome=false → compta com a despesa + INCOHERÈNCIA
///  - Transfers: exclosos estructuralment (viuen a `transfers`, no a `transactions`).

/// Versió de la semàntica de càlcul. Els cycle_reports la desen per saber amb
/// quines regles es van generar (els vells, sense el camp, es llegeixen com a 0).
const int kLedgerSchemaVersion = 1;

enum LedgerBucket { income, expense, saved, withdrawn }

class Incoherence {
  final String? txId;
  final String type; // 'tipus' | 'guardiola-creuada'
  final String message;
  const Incoherence({this.txId, required this.type, required this.message});
}

/// Classificació d'un moviment: a quin cistell va i amb quin delta (el refund
/// aporta delta negatiu al cistell de despesa), i les incoherències detectades.
///
/// El cistell (exclusió dels totals) i els flags d'incoherència són
/// INDEPENDENTS: un moviment pot estar correctament exclòs (guardiola) i alhora
/// estar mal categoritzat, i cal veure'l per corregir-lo.
class TxClass {
  final LedgerBucket bucket;
  final double delta;
  final List<Incoherence> incoherences;
  const TxClass(this.bucket, this.delta, {this.incoherences = const []});
}

/// Índexs precalculats un sol cop per no recórrer categories per cada moviment.
class LedgerLookups {
  final Map<String, TransactionType> typeByCategoryId;
  final Map<String, String?> linkedGoalBySubId;

  const LedgerLookups(this.typeByCategoryId, this.linkedGoalBySubId);

  factory LedgerLookups.from(List<Category> categories) {
    final types = <String, TransactionType>{};
    final links = <String, String?>{};
    for (final c in categories) {
      types[c.id] = c.type;
      for (final s in c.subcategories) {
        links[s.id] = s.linkedSavingsGoalId;
      }
    }
    return LedgerLookups(types, links);
  }
}

/// Classifica UN moviment segons les regles canòniques.
TxClass classifyTransaction(Transaction tx, LedgerLookups look) {
  final subGoal = look.linkedGoalBySubId[tx.subCategoryId];
  final isSavings = tx.savingsGoalId != null || subGoal != null;
  final type = look.typeByCategoryId[tx.categoryId];

  // ── FLAGS D'INCOHERÈNCIA (independents del cistell) ──
  final incoherences = <Incoherence>[];

  // Tipus: despesa (isIncome=false) sota una categoria d'INGRÉS. Es marca fins i
  // tot si el moviment és de guardiola i queda exclòs dels totals.
  if (type == TransactionType.income && !tx.isIncome) {
    incoherences.add(Incoherence(
      txId: tx.id,
      type: 'tipus',
      message: 'Despesa (isIncome=false) sota una categoria d\'ingrés.',
    ));
  }
  // D5: savingsGoalId i subcategoria enllaçada apunten a guardioles DIFERENTS.
  if (tx.savingsGoalId != null &&
      subGoal != null &&
      subGoal != tx.savingsGoalId) {
    incoherences.add(Incoherence(
      txId: tx.id,
      type: 'guardiola-creuada',
      message:
          'Moviment amb guardiola pròpia i subcategoria enllaçada a una guardiola diferent.',
    ));
  }

  // ── CISTELL + DELTA (exclusió, independent dels flags) ──
  final LedgerBucket bucket;
  final double delta;

  if (isSavings) {
    // Moviment de guardiola → fora dels totals.
    bucket = tx.isIncome ? LedgerBucket.withdrawn : LedgerBucket.saved;
    delta = tx.amount;
  } else if (type == TransactionType.income) {
    // Ingrés normal, o mal tipat (compta com a despesa pel seu isIncome).
    bucket = tx.isIncome ? LedgerBucket.income : LedgerBucket.expense;
    delta = tx.amount;
  } else if (type == TransactionType.expense) {
    // Despesa; el refund (isIncome=true) resta.
    bucket = LedgerBucket.expense;
    delta = tx.isIncome ? -tx.amount : tx.amount;
  } else {
    // Categoria desconeguda (esborrada/legacy): cistell segons isIncome.
    bucket = tx.isIncome ? LedgerBucket.income : LedgerBucket.expense;
    delta = tx.amount;
  }

  return TxClass(bucket, delta, incoherences: incoherences);
}

/// Resultat agregat d'un conjunt de moviments (ja filtrats per finestra pel qui
/// crida). Invariant: totalIncome == Σ incomeByCategory, totalExpense == Σ
/// expenseByCategory (sense filtrar res; els filtres de ≤0 són PRESENTACIÓ).
class LedgerSummary {
  double totalIncome = 0;
  double totalExpense = 0;
  double savedThisCycle = 0;
  double withdrawnThisCycle = 0;
  final Map<String, double> incomeByCategory = {};
  final Map<String, double> expenseByCategory = {};
  final List<Incoherence> incoherences = [];

  /// Estalvi net del cicle.
  double get netSaved => savedThisCycle - withdrawnThisCycle;
}

/// Suma un conjunt de moviments amb les regles canòniques.
LedgerSummary summarizeLedger(
  Iterable<Transaction> txs,
  LedgerLookups look,
) {
  final s = LedgerSummary();
  for (final tx in txs) {
    final c = classifyTransaction(tx, look);
    switch (c.bucket) {
      case LedgerBucket.income:
        s.totalIncome += c.delta;
        s.incomeByCategory[tx.categoryId] =
            (s.incomeByCategory[tx.categoryId] ?? 0) + c.delta;
        break;
      case LedgerBucket.expense:
        s.totalExpense += c.delta;
        s.expenseByCategory[tx.categoryId] =
            (s.expenseByCategory[tx.categoryId] ?? 0) + c.delta;
        break;
      case LedgerBucket.saved:
        s.savedThisCycle += c.delta;
        break;
      case LedgerBucket.withdrawn:
        s.withdrawnThisCycle += c.delta;
        break;
    }
    s.incoherences.addAll(c.incoherences);
  }
  return s;
}
