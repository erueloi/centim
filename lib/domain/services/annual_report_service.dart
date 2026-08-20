import 'package:intl/intl.dart';
import '../models/annual_report.dart';
import '../models/billing_cycle.dart';
import '../models/category.dart';
import '../models/debt_account.dart';
import '../models/transaction.dart';
import 'ledger_service.dart';

class AnnualReportService {
  /// Consolidacions canòniques conegudes de categories fusionades.
  /// Mapeja variants de noms a noms canònics unificats.
  static const Map<String, String> _categoryNameMerges = {
    'cura personal / mascotes': 'Cura Personal',
    'cura personal': 'Cura Personal',
    'estalvi menusal': 'Estalvi',
    'estalvi mensual': 'Estalvi',
    'estalvi': 'Estalvi',
  };

  /// Noms de subcategories que són regularitzacions internes i NO deute bancari.
  static const Set<String> _internalDebtAdjustmentSubcategories = {
    'negatius comptes a tornar',
    'retornar diners',
    'regularitzacio interna',
    'regularització interna',
  };

  /// Normalitza el nom d'una categoria per a consolidar fusions.
  static String canonicalCategoryName(String rawName) {
    final lower = rawName.trim().toLowerCase();
    return _categoryNameMerges[lower] ?? rawName.trim();
  }

  /// Neteja el nom d'una subcategoria per a eliminar marcadors tècnics com (antic) o (arxivat).
  static String cleanSubcategoryName(String rawName) {
    var cleaned = rawName.trim();
    // Eliminar sufixos tècnics d'arxiu
    cleaned = cleaned
        .replaceAll(RegExp(r'\s*\((antic|arxivat|vell|antiga|arxivada)\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\[(antic|arxivat|vell|antiga|arxivada)\]', caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return 'Altres';
    return cleaned;
  }

  /// Indica si una subcategoria és regularització interna (no deute bancari).
  static bool isInternalAdjustment(String subcategoryName) {
    final lower = subcategoryName.trim().toLowerCase();
    return _internalDebtAdjustmentSubcategories.contains(lower);
  }

  /// Constants canòniques per a llindars de projecció anual
  static const int kMinCyclesForProjection = 3;
  static const int kEmptyCyclesThreshold = 0;

  /// ID canònic per a transaccions amb categories orfes o desconegudes
  static const String kUnclassifiedCategoryId = 'unclassified_expenses';

  /// Calcula l'informe complet per a un any concret.
  static AnnualReportData calculateAnnualReport({
    required int targetYear,
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<BillingCycle> cycles,
    required List<DebtAccount> debts,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();

    // 1. Identificar els cicles corresponents a l'any objectiu (targetYear).
    final yearCycles = _getCyclesForYear(cycles, targetYear);
    final totalCyclesInYear = yearCycles.isNotEmpty ? yearCycles.length : 12;

    // 2. Classificar cicles: complets (amb dades / passats) vs restants.
    final completedCycles = yearCycles.where((cycle) {
      // Un cicle és complet si ha finalitzat abans d'ara mateix
      return cycle.endDate.isBefore(now);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final int completedCyclesCount;
    final int remainingCyclesCount;

    if (yearCycles.isNotEmpty) {
      completedCyclesCount = completedCycles.length;
      remainingCyclesCount = (totalCyclesInYear - completedCyclesCount).clamp(0, totalCyclesInYear);
    } else {
      // Fallback a mesos naturals de l'any
      if (targetYear < now.year) {
        completedCyclesCount = 12;
        remainingCyclesCount = 0;
      } else if (targetYear == now.year) {
        completedCyclesCount = (now.month - 1).clamp(0, 12);
        remainingCyclesCount = (12 - completedCyclesCount).clamp(0, 12);
      } else {
        completedCyclesCount = 0;
        remainingCyclesCount = 12;
      }
    }

    // Dates del període de cicles completats
    DateTime? periodStartDate;
    DateTime? periodEndDate;
    if (completedCycles.isNotEmpty) {
      periodStartDate = completedCycles.first.startDate;
      periodEndDate = completedCycles.last.endDate;
    }

    // 3. Obtenir les transaccions de l'any i dels cicles complets
    final look = LedgerLookups.from(categories);
    final completedCycleTransactions = _getTransactionsInCycles(
      transactions: transactions,
      cycles: completedCycles,
      targetYear: targetYear,
      useNaturalMonthsIfNoCycles: yearCycles.isEmpty,
      completedMonthsCount: completedCyclesCount,
    );

    if (periodStartDate == null && completedCycleTransactions.isNotEmpty) {
      final sortedTxs = List<Transaction>.from(completedCycleTransactions)
        ..sort((a, b) => a.date.compareTo(b.date));
      periodStartDate = sortedTxs.first.date;
      periodEndDate = sortedTxs.last.date;
    }

    // Categories mapejades per ID
    final categoryById = {for (final c in categories) c.id: c};

    // Subcategories mapejades per categoria i ID
    final subcategoryByKey = <String, SubCategory>{
      for (final c in categories)
        for (final s in c.subcategories) '${c.id}:${s.id}': s,
    };

    // 4. Mapejar consolidacions per ID canònic
    final canonicalCategoryMap = _buildCanonicalCategoryIndex(categories);

    // 5. Agrupació d'ingressos, despeses i guardioles
    double totalRealRecurringIncome = 0;
    double totalRealVariableIncome = 0;
    double totalRealSavingsDeposits = 0;
    int totalRealSavingsDepositsCount = 0;
    double totalRealSavingsWithdrawals = 0;
    int totalRealSavingsWithdrawalsCount = 0;

    final realSpentByCategory = <String, double>{};
    final realSpentBySubcategory = <String, Map<String, double>>{};
    final realIncomeByCategory = <String, double>{};
    final realIncomeBySubcategory = <String, Map<String, double>>{};
    final historicalSubcategoryNames = <String, String>{};

    // Per al servei de deute bancari
    double realDebtService = 0;

    for (final tx in completedCycleTransactions) {
      final c = classifyTransaction(tx, look);

      // Moviments de guardiola / estalvi (Aportacions i Retirades)
      if (c.bucket == LedgerBucket.saved) {
        totalRealSavingsDeposits += c.delta;
        totalRealSavingsDepositsCount++;
        continue;
      }
      if (c.bucket == LedgerBucket.withdrawn) {
        totalRealSavingsWithdrawals += c.delta;
        totalRealSavingsWithdrawalsCount++;
        continue;
      }

      // Ingressos canònics (exclou guardioles)
      if (c.bucket == LedgerBucket.income) {
        final subcategory = subcategoryByKey['${tx.categoryId}:${tx.subCategoryId}'];
        final rawCat = categoryById[tx.categoryId];
        final isPayroll = rawCat?.name.toLowerCase().contains('nòmina') == true ||
            rawCat?.name.toLowerCase().contains('nomina') == true ||
            tx.categoryName.toLowerCase().contains('nòmina') == true ||
            tx.categoryName.toLowerCase().contains('nomina') == true;
        final isRecurring = subcategory?.isFixed == true || isPayroll;

        if (isRecurring) {
          totalRealRecurringIncome += c.delta;
        } else {
          totalRealVariableIncome += c.delta;
        }

        final rawCategory = categoryById[tx.categoryId];
        final canonicalCat = canonicalCategoryMap[tx.categoryId] ?? rawCategory;
        final canonicalId = canonicalCat?.id ??
            (rawCategory != null && tx.categoryId.isNotEmpty ? tx.categoryId : kUnclassifiedCategoryId);
        realIncomeByCategory[canonicalId] = (realIncomeByCategory[canonicalId] ?? 0) + c.delta;

        final subKey = tx.subCategoryId.isEmpty ? '__without_subcategory__' : tx.subCategoryId;
        final subMap = realIncomeBySubcategory.putIfAbsent(canonicalId, () => {});
        subMap[subKey] = (subMap[subKey] ?? 0) + c.delta;

        if (tx.subCategoryName.isNotEmpty) {
          historicalSubcategoryNames['$canonicalId:$subKey'] = tx.subCategoryName;
        }
        continue;
      }

      if (c.bucket != LedgerBucket.expense) continue;

      // Trobar categoria canònica (o unificar sota Altres sense classificar si és desconeguda)
      final rawCategory = categoryById[tx.categoryId];
      final canonicalCat = canonicalCategoryMap[tx.categoryId] ?? rawCategory;
      final canonicalId = canonicalCat?.id ??
          (rawCategory != null ? tx.categoryId : kUnclassifiedCategoryId);

      realSpentByCategory[canonicalId] = (realSpentByCategory[canonicalId] ?? 0) + c.delta;

      final subKey = tx.subCategoryId.isEmpty ? '__without_subcategory__' : tx.subCategoryId;
      final subMap = realSpentBySubcategory.putIfAbsent(canonicalId, () => {});
      subMap[subKey] = (subMap[subKey] ?? 0) + c.delta;

      if (tx.subCategoryName.isNotEmpty) {
        historicalSubcategoryNames['$canonicalId:$subKey'] = tx.subCategoryName;
      }

      // Verificació de Servei de Deute Bancari
      final subcategory = subcategoryByKey['${tx.categoryId}:${tx.subCategoryId}'];
      final subName = subcategory?.name ?? tx.subCategoryName;
      final isInternal = isInternalAdjustment(subName);

      if (!isInternal) {
        final isLinkedToDebt = subcategory?.linkedDebtId != null ||
            debts.any((d) => d.linkedExpenseCategoryId == tx.categoryId);
        final isDebtCategory = rawCategory?.name.toLowerCase().contains('préstec') == true ||
            rawCategory?.name.toLowerCase().contains('prestec') == true ||
            rawCategory?.name.toLowerCase().contains('crèdit') == true ||
            rawCategory?.name.toLowerCase().contains('credit') == true ||
            rawCategory?.name.toLowerCase().contains('deute') == true;

        if (isLinkedToDebt || isDebtCategory) {
          realDebtService += c.delta;
        }
      }
    }

    // 6. Càlculs totals i projeccions globals
    // Despeses
    final totalRealExpense = realSpentByCategory.values.fold(0.0, (sum, val) => sum + val);
    final monthlyAverageExpense = completedCyclesCount > 0 ? totalRealExpense / completedCyclesCount : 0.0;
    final projectedAnnualExpense = totalRealExpense + (monthlyAverageExpense * remainingCyclesCount);

    // Ingressos
    final totalRealIncome = totalRealRecurringIncome + totalRealVariableIncome;
    final monthlyAverageRecurringIncome = completedCyclesCount > 0 ? totalRealRecurringIncome / completedCyclesCount : 0.0;
    final monthlyAverageVariableIncome = completedCyclesCount > 0 ? totalRealVariableIncome / completedCyclesCount : 0.0;
    final monthlyAverageIncome = completedCyclesCount > 0 ? totalRealIncome / completedCyclesCount : 0.0;

    // Projecció conservadora:
    // - Recurrents (nòmines): s'anualitzen a 12 mesos
    // - Variables / puntuals: no s'inflen pel futur, només sumen el que ja s'ha ingressat de debò
    final projectedAnnualRecurringIncome = monthlyAverageRecurringIncome * 12;
    final projectedAnnualVariableIncome = totalRealVariableIncome;
    final projectedAnnualIncome = projectedAnnualRecurringIncome + projectedAnnualVariableIncome;

    // Servei de deute projectat
    final debtServiceMonthlyAvg = completedCyclesCount > 0 ? realDebtService / completedCyclesCount : 0.0;
    final debtServiceAnnualTotal = realDebtService + (debtServiceMonthlyAvg * remainingCyclesCount);
    final debtServicePercentage = projectedAnnualExpense > 0 ? debtServiceAnnualTotal / projectedAnnualExpense : 0.0;

    // 7. Càlcul any anterior (N-1) per a comparativa interanual
    final previousYearData = _calculatePreviousYearMap(
      targetYear: targetYear - 1,
      transactions: transactions,
      categories: categories,
      cycles: cycles,
      canonicalCategoryMap: canonicalCategoryMap,
      look: look,
    );
    final hasPrevYearData = previousYearData.isNotEmpty;

    // 8. Construcció de la llista d'AnnualCategoryData (Despeses)
    // Recollim totes les categories amb despesa o de la llista oficial
    final allCategoryIds = {...realSpentByCategory.keys};
    for (final c in categories) {
      if (c.type == TransactionType.expense && !c.archived) {
        final canCat = canonicalCategoryMap[c.id] ?? c;
        allCategoryIds.add(canCat.id);
      }
    }

    final categoryResults = <AnnualCategoryData>[];

    for (final catId in allCategoryIds) {
      final isUnclassified = catId == kUnclassifiedCategoryId;
      final category = isUnclassified
          ? const Category(
              id: kUnclassifiedCategoryId,
              name: 'Altres (sense classificar)',
              icon: '📦',
              type: TransactionType.expense,
            )
          : (categoryById[catId] ??
              Category(
                id: catId,
                name: 'Altres',
                icon: '📦',
                type: TransactionType.expense,
              ));

      final realSpent = realSpentByCategory[catId] ?? 0.0;
      final monthlyAvg = completedCyclesCount > 0 ? realSpent / completedCyclesCount : 0.0;
      final projectedAnnual = realSpent + (monthlyAvg * remainingCyclesCount);
      final percentageOfTotal = projectedAnnualExpense > 0 ? projectedAnnual / projectedAnnualExpense : 0.0;

      // Subcategories
      final subMap = realSpentBySubcategory[catId] ?? {};
      final allSubKeys = {...subMap.keys};
      for (final s in category.subcategories) {
        if (!s.archived) allSubKeys.add(s.id);
      }

      final subResults = <AnnualSubcategoryData>[];
      for (final subKey in allSubKeys) {
        final subSpent = subMap[subKey] ?? 0.0;
        final subMonthlyAvg = completedCyclesCount > 0 ? subSpent / completedCyclesCount : 0.0;
        final subProjectedAnnual = subSpent + (subMonthlyAvg * remainingCyclesCount);
        final subPctCat = projectedAnnual > 0 ? subProjectedAnnual / projectedAnnual : 0.0;
        final subPctTotal = projectedAnnualExpense > 0 ? subProjectedAnnual / projectedAnnualExpense : 0.0;

        final subObj = subcategoryByKey['$catId:$subKey'];
        final rawSubName = subKey == '__without_subcategory__'
            ? 'Sense subcategoria'
            : (subObj?.name ?? historicalSubcategoryNames['$catId:$subKey'] ?? 'Subcategoria');
        final cleanName = cleanSubcategoryName(rawSubName);

        // Any anterior subcategoria
        final prevSubAnnual = previousYearData['$catId:$subKey'];
        // Només mostrem percentatge si l'any anterior tenia una despesa significativa (mínim 50€)
        final double? subYoYDelta = (prevSubAnnual != null && prevSubAnnual >= 50.0)
            ? (subProjectedAnnual - prevSubAnnual) / prevSubAnnual
            : null;

        if (subProjectedAnnual > 0 || subSpent > 0) {
          subResults.add(AnnualSubcategoryData(
            id: subKey,
            name: cleanName,
            realSpent: subSpent,
            monthlyAverage: subMonthlyAvg,
            projectedAnnualTotal: subProjectedAnnual,
            percentageOfCategory: subPctCat,
            percentageOfTotal: subPctTotal,
            previousYearAnnualTotal: prevSubAnnual,
            yearOverYearDelta: subYoYDelta,
          ));
        }
      }

      // Ordenar subcategories per total descendent
      subResults.sort((a, b) => b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal));

      // Any anterior categoria
      final prevCatAnnual = previousYearData[catId];
      final double? catYoYDelta = (prevCatAnnual != null && prevCatAnnual >= 50.0)
          ? (projectedAnnual - prevCatAnnual) / prevCatAnnual
          : null;

      if (projectedAnnual > 0 || realSpent > 0) {
        categoryResults.add(AnnualCategoryData(
          categoryId: catId,
          categoryName: canonicalCategoryName(category.name),
          icon: category.icon,
          color: category.color,
          realSpent: realSpent,
          monthlyAverage: monthlyAvg,
          projectedAnnualTotal: projectedAnnual,
          percentageOfTotal: percentageOfTotal,
          subcategories: subResults,
          previousYearAnnualTotal: prevCatAnnual,
          yearOverYearDelta: catYoYDelta,
        ));
      }
    }

    // Ordenar categories per import anual descendent
    categoryResults.sort((a, b) => b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal));

    // 9. Construcció de la llista d'AnnualCategoryData (Ingressos)
    final allIncomeCategoryIds = {...realIncomeByCategory.keys};
    for (final c in categories) {
      if (c.type == TransactionType.income && !c.archived) {
        allIncomeCategoryIds.add(c.id);
      }
    }

    final incomeCategoryResults = <AnnualCategoryData>[];

    for (final catId in allIncomeCategoryIds) {
      final isUnclassified = catId == kUnclassifiedCategoryId || catId.isEmpty;
      final category = isUnclassified
          ? const Category(
              id: kUnclassifiedCategoryId,
              name: 'Altres (sense classificar)',
              icon: '📦',
              type: TransactionType.income,
            )
          : (categoryById[catId] ??
              Category(
                id: catId,
                name: 'Altres (sense classificar)',
                icon: '📦',
                type: TransactionType.income,
              ));

      final realIncome = realIncomeByCategory[catId] ?? 0.0;
      final monthlyAvg = completedCyclesCount > 0 ? realIncome / completedCyclesCount : 0.0;
      final isPayrollCat = category.name.toLowerCase().contains('nòmina') || category.name.toLowerCase().contains('nomina');
      final projectedAnnual = isPayrollCat ? (monthlyAvg * 12) : realIncome;
      final percentageOfTotal = projectedAnnualIncome > 0 ? projectedAnnual / projectedAnnualIncome : 0.0;

      final subMap = realIncomeBySubcategory[catId] ?? {};
      final allSubKeys = {...subMap.keys};
      for (final s in category.subcategories) {
        if (!s.archived) allSubKeys.add(s.id);
      }

      final subResults = <AnnualSubcategoryData>[];
      for (final subKey in allSubKeys) {
        final subIncome = subMap[subKey] ?? 0.0;
        final subMonthlyAvg = completedCyclesCount > 0 ? subIncome / completedCyclesCount : 0.0;
        final subObj = subcategoryByKey['$catId:$subKey'];
        final isRecurringSub = subObj?.isFixed == true || isPayrollCat;
        final subProjectedAnnual = isRecurringSub ? (subMonthlyAvg * 12) : subIncome;
        final subPctCat = projectedAnnual > 0 ? subProjectedAnnual / projectedAnnual : 0.0;
        final subPctTotal = projectedAnnualIncome > 0 ? subProjectedAnnual / projectedAnnualIncome : 0.0;

        final rawSubName = subKey == '__without_subcategory__'
            ? 'Sense subcategoria'
            : (subObj?.name ?? historicalSubcategoryNames['$catId:$subKey'] ?? 'Subcategoria');
        final cleanName = cleanSubcategoryName(rawSubName);

        if (subProjectedAnnual > 0 || subIncome > 0) {
          subResults.add(AnnualSubcategoryData(
            id: subKey,
            name: cleanName,
            realSpent: subIncome,
            monthlyAverage: subMonthlyAvg,
            projectedAnnualTotal: subProjectedAnnual,
            percentageOfCategory: subPctCat,
            percentageOfTotal: subPctTotal,
          ));
        }
      }

      subResults.sort((a, b) => b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal));

      if (projectedAnnual > 0 || realIncome > 0) {
        incomeCategoryResults.add(AnnualCategoryData(
          categoryId: catId,
          categoryName: canonicalCategoryName(category.name),
          icon: category.icon,
          color: category.color,
          realSpent: realIncome,
          monthlyAverage: monthlyAvg,
          projectedAnnualTotal: projectedAnnual,
          percentageOfTotal: percentageOfTotal,
          subcategories: subResults,
        ));
      }
    }

    incomeCategoryResults.sort((a, b) => b.projectedAnnualTotal.compareTo(a.projectedAnnualTotal));

    return AnnualReportData(
      year: targetYear,
      totalRealIncome: totalRealIncome,
      totalRealRecurringIncome: totalRealRecurringIncome,
      totalRealVariableIncome: totalRealVariableIncome,
      projectedAnnualIncome: projectedAnnualIncome,
      projectedAnnualRecurringIncome: projectedAnnualRecurringIncome,
      projectedAnnualVariableIncome: projectedAnnualVariableIncome,
      monthlyAverageIncome: monthlyAverageIncome,
      monthlyAverageRecurringIncome: monthlyAverageRecurringIncome,
      monthlyAverageVariableIncome: monthlyAverageVariableIncome,
      totalRealExpense: totalRealExpense,
      projectedAnnualExpense: projectedAnnualExpense,
      monthlyAverageExpense: monthlyAverageExpense,
      completedCyclesCount: completedCyclesCount,
      remainingCyclesCount: remainingCyclesCount,
      totalCyclesInYear: totalCyclesInYear,
      debtServiceAnnualTotal: debtServiceAnnualTotal,
      debtServiceMonthlyAverage: debtServiceMonthlyAvg,
      debtServicePercentage: debtServicePercentage,
      categories: categoryResults,
      incomeCategories: incomeCategoryResults,
      hasPreviousYearData: hasPrevYearData,
      periodStartDate: periodStartDate,
      periodEndDate: periodEndDate,
      totalRealSavingsDeposits: totalRealSavingsDeposits,
      totalRealSavingsDepositsCount: totalRealSavingsDepositsCount,
      totalRealSavingsWithdrawals: totalRealSavingsWithdrawals,
      totalRealSavingsWithdrawalsCount: totalRealSavingsWithdrawalsCount,
    );
  }

  /// Filtra i retorna els cicles que pertanyen a l'any indicat.
  static List<BillingCycle> _getCyclesForYear(List<BillingCycle> cycles, int year) {
    return cycles.where((c) {
      return c.endDate.year == year || (c.startDate.year == year && c.endDate.year == year);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Extreu les transaccions dels cicles complets
  static List<Transaction> _getTransactionsInCycles({
    required List<Transaction> transactions,
    required List<BillingCycle> cycles,
    required int targetYear,
    required bool useNaturalMonthsIfNoCycles,
    required int completedMonthsCount,
  }) {
    if (cycles.isNotEmpty) {
      return transactions.where((tx) {
        final txDate = tx.date;
        return cycles.any((cycle) {
          final s = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day, 0, 0, 0);
          final e = DateTime(cycle.endDate.year, cycle.endDate.month, cycle.endDate.day, 23, 59, 59);
          return (txDate.isAtSameMomentAs(s) || txDate.isAfter(s)) &&
              (txDate.isAtSameMomentAs(e) || txDate.isBefore(e));
        });
      }).toList();
    }

    // Si no hi ha cicles explícits: mesos naturals complets de l'any
    if (completedMonthsCount <= 0) return [];
    final startOfYear = DateTime(targetYear, 1, 1);
    final endOfCompleted = DateTime(targetYear, completedMonthsCount + 1, 0, 23, 59, 59);

    return transactions.where((tx) {
      return (tx.date.isAtSameMomentAs(startOfYear) || tx.date.isAfter(startOfYear)) &&
          (tx.date.isAtSameMomentAs(endOfCompleted) || tx.date.isBefore(endOfCompleted));
    }).toList();
  }

  /// Construeix l'índex de mapeig per unificar categories consolidades
  static Map<String, Category> _buildCanonicalCategoryIndex(List<Category> categories) {
    final map = <String, Category>{};
    final canonicalByName = <String, Category>{};

    for (final cat in categories) {
      final canName = canonicalCategoryName(cat.name).toLowerCase();
      if (!canonicalByName.containsKey(canName)) {
        canonicalByName[canName] = cat;
      }
    }

    for (final cat in categories) {
      final canName = canonicalCategoryName(cat.name).toLowerCase();
      map[cat.id] = canonicalByName[canName] ?? cat;
    }

    return map;
  }

  /// Calcula el mapa de despesa anual de l'any anterior per a comparatives.
  /// Retorna buit `{}` si l'any anterior té menys de 3 mesos/cicles amb dades.
  static Map<String, double> _calculatePreviousYearMap({
    required int targetYear,
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<BillingCycle> cycles,
    required Map<String, Category> canonicalCategoryMap,
    required LedgerLookups look,
  }) {
    final prevYearCycles = _getCyclesForYear(cycles, targetYear);
    final prevTxs = _getTransactionsInCycles(
      transactions: transactions,
      cycles: prevYearCycles,
      targetYear: targetYear,
      useNaturalMonthsIfNoCycles: prevYearCycles.isEmpty,
      completedMonthsCount: 12,
    );

    if (prevTxs.isEmpty) return {};

    // Comprovar quants mesos diferents contenen despeses canòniques
    final activeMonths = <int>{};
    for (final tx in prevTxs) {
      final c = classifyTransaction(tx, look);
      if (c.bucket == LedgerBucket.expense) {
        activeMonths.add(tx.date.month);
      }
    }

    // Si té menys de 3 mesos amb despesa, NO és estadísticament comparable
    if (activeMonths.length < 3) {
      return {};
    }

    final result = <String, double>{};
    for (final tx in prevTxs) {
      final c = classifyTransaction(tx, look);
      if (c.bucket != LedgerBucket.expense) continue;

      final rawCat = categories.where((cat) => cat.id == tx.categoryId).firstOrNull;
      final canonicalCat = canonicalCategoryMap[tx.categoryId] ?? rawCat;
      final canonicalId = canonicalCat?.id ??
          (rawCat != null ? tx.categoryId : kUnclassifiedCategoryId);

      result[canonicalId] = (result[canonicalId] ?? 0) + c.delta;
      final subKey = tx.subCategoryId.isEmpty ? '__without_subcategory__' : tx.subCategoryId;
      result['$canonicalId:$subKey'] = (result['$canonicalId:$subKey'] ?? 0) + c.delta;
    }

    return result;
  }

  /// Genera un resum executiu en text net, ideal per copiar al portapapers i compartir amb el banc.
  static String generateExecutiveSummary(AnnualReportData data) {
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: '€', decimalDigits: 0);
    final pctFormat = NumberFormat.percentPattern('ca_ES');

    final sb = StringBuffer();
    sb.writeln('═══════════════════════════════════════════');
    sb.writeln('     CÈNTIM · VISTA ANUAL (${data.year})     ');
    sb.writeln('═══════════════════════════════════════════\n');

    sb.writeln('📌 BALANÇ ANUAL (INGRESSOS vs DESPESES):');
    sb.writeln('• Ingressos anuals estimats: ${currency.format(data.projectedAnnualIncome)} / any (${currency.format(data.monthlyAverageIncome)} / mes)');
    sb.writeln('• Despesa anual total: ${currency.format(data.projectedAnnualExpense)} / any (${currency.format(data.monthlyAverageExpense)} / mes)');
    final diff = data.netAnnualDifference;
    final diffSign = diff >= 0 ? '+' : '−';
    sb.writeln('• Diferencial net anual: $diffSign${currency.format(diff.abs())} / any');
    sb.writeln('');

    sb.writeln('📌 DETALL DE DESPESA:');
    sb.writeln('• Despesa real acumulada (${data.completedCyclesCount} mesos): ${currency.format(data.totalRealExpense)}');
    if (data.remainingCyclesCount > 0) {
      final projectedRemaining = data.projectedAnnualExpense - data.totalRealExpense;
      sb.writeln('• Projecció restant (${data.remainingCyclesCount} mesos): ${currency.format(projectedRemaining)}');
    }
    sb.writeln('');

    sb.writeln('🏦 SERVEI DE DEUTE BANCARI:');
    sb.writeln('• Quota anual de deute: ${currency.format(data.debtServiceAnnualTotal)} / any');
    sb.writeln('• Mitjana mensual de deute: ${currency.format(data.debtServiceMonthlyAverage)} / mes');
    sb.writeln('• Pes sobre la despesa anual: ${(data.debtServicePercentage * 100).toStringAsFixed(1)}%');
    sb.writeln('');

    sb.writeln('📊 DESGLOSSAMENT PER CATEGORIES:');
    sb.writeln('───────────────────────────────────────────');
    for (final cat in data.categories) {
      final pct = pctFormat.format(cat.percentageOfTotal);
      sb.writeln('${cat.icon} ${cat.categoryName.toUpperCase()}: ${currency.format(cat.projectedAnnualTotal)}/any (${currency.format(cat.monthlyAverage)}/mes · $pct)');
      for (final sub in cat.subcategories) {
        sb.writeln('   └─ ${sub.name}: ${currency.format(sub.projectedAnnualTotal)}/any (${currency.format(sub.monthlyAverage)}/mes · ${(sub.percentageOfCategory * 100).toStringAsFixed(0)}%)');
      }
    }
    sb.writeln('───────────────────────────────────────────');
    sb.writeln('Generat automàticament per Cèntim');

    return sb.toString();
  }

  /// Genera contingut CSV per a exportació.
  static String exportToCsv(AnnualReportData data) {
    final sb = StringBuffer();
    sb.writeln('Any;Tipus;Categoria;Subcategoria;Despesa Real;Mitjana Mensual;Total Anual;Percentatge');

    // Titulars globals
    sb.writeln('${data.year};INGRESSOS;Ingressos de la Llar;;${data.totalRealIncome.toStringAsFixed(2)};${data.monthlyAverageIncome.toStringAsFixed(2)};${data.projectedAnnualIncome.toStringAsFixed(2)};-');
    sb.writeln('${data.year};TOTAL;Despesa Anual Total;;${data.totalRealExpense.toStringAsFixed(2)};${data.monthlyAverageExpense.toStringAsFixed(2)};${data.projectedAnnualExpense.toStringAsFixed(2)};100.0%');
    sb.writeln('${data.year};DIFERENCIAL;Diferencial Net (Ingressos - Despeses);;${(data.totalRealIncome - data.totalRealExpense).toStringAsFixed(2)};${data.monthlyNetDifference.toStringAsFixed(2)};${data.netAnnualDifference.toStringAsFixed(2)};-');
    sb.writeln('${data.year};DEUTE;Servei de Deute Bancari;;;${data.debtServiceMonthlyAverage.toStringAsFixed(2)};${data.debtServiceAnnualTotal.toStringAsFixed(2)};${(data.debtServicePercentage * 100).toStringAsFixed(2)}%');

    for (final cat in data.categories) {
      sb.writeln('${data.year};CATEGORIA;${cat.categoryName};;${cat.realSpent.toStringAsFixed(2)};${cat.monthlyAverage.toStringAsFixed(2)};${cat.projectedAnnualTotal.toStringAsFixed(2)};${(cat.percentageOfTotal * 100).toStringAsFixed(2)}%');
      for (final sub in cat.subcategories) {
        sb.writeln('${data.year};SUBCATEGORIA;${cat.categoryName};${sub.name};${sub.realSpent.toStringAsFixed(2)};${sub.monthlyAverage.toStringAsFixed(2)};${sub.projectedAnnualTotal.toStringAsFixed(2)};${(sub.percentageOfTotal * 100).toStringAsFixed(2)}%');
      }
    }

    return sb.toString();
  }

  /// Algorisme de repartiment per residus més grans (Largest Remainder Method / Hamilton).
  /// Garanteix que la suma dels percentatges enters sigui exactament igual a [targetSum] (100).
  static List<int> largestRemainderPercentages(
    List<double> rawValues, {
    int targetSum = 100,
  }) {
    if (rawValues.isEmpty) return const [];
    final total = rawValues.fold(0.0, (acc, v) => acc + (v > 0 ? v : 0.0));
    if (total <= 0) {
      return List.filled(rawValues.length, 0);
    }

    final exact = rawValues.map((v) => (v > 0 ? (v / total) * targetSum : 0.0)).toList();
    final floors = exact.map((v) => v.floor()).toList();
    final floorSum = floors.fold(0, (acc, v) => acc + v);
    var remainder = targetSum - floorSum;

    final remainders = List.generate(
      rawValues.length,
      (i) => (index: i, remainder: exact[i] - floors[i]),
    )..sort((a, b) => b.remainder.compareTo(a.remainder));

    final result = List<int>.from(floors);
    for (var i = 0; i < remainder && i < remainders.length; i++) {
      result[remainders[i].index]++;
    }

    return result;
  }
}
