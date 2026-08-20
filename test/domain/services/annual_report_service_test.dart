import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/billing_cycle.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/domain/models/debt_account.dart';
import 'package:centim/domain/models/transaction.dart';
import 'package:centim/domain/services/annual_report_service.dart';
import 'package:centim/domain/services/annual_report_pdf_service.dart';

void main() {
  group('AnnualReportService Tests', () {
    final now = DateTime(2026, 4, 15); // Mitjans d'Abril 2026 (3 mesos complets: Gen, Feb, Mar)

    final catCura = const Category(
      id: 'cat_cura',
      name: 'Cura Personal',
      icon: '🧴',
      type: TransactionType.expense,
      subcategories: [
        SubCategory(id: 'sub_cura_general', name: 'General', monthlyBudget: 50),
        SubCategory(id: 'sub_mascotes', name: 'Mascotes', monthlyBudget: 50),
      ],
    );

    final catCuraOld = const Category(
      id: 'cat_cura_old',
      name: 'Cura Personal / Mascotes',
      icon: '🐕',
      type: TransactionType.expense,
      subcategories: [
        SubCategory(id: 'sub_cura_old', name: 'Veterinari', monthlyBudget: 50),
      ],
    );

    final catDeute = const Category(
      id: 'cat_deute',
      name: 'Préstecs i Crèdits',
      icon: '🏦',
      type: TransactionType.expense,
      subcategories: [
        SubCategory(
          id: 'sub_hipoteca',
          name: 'Quota Hipoteca',
          monthlyBudget: 600,
          linkedDebtId: 'debt_hipoteca',
        ),
        SubCategory(
          id: 'sub_negatius',
          name: 'Negatius comptes a tornar',
          monthlyBudget: 100,
        ),
        SubCategory(
          id: 'sub_retornar',
          name: 'Retornar diners',
          monthlyBudget: 50,
        ),
      ],
    );

    final catAlimentacio = const Category(
      id: 'cat_menjar',
      name: 'Alimentació',
      icon: '🛒',
      type: TransactionType.expense,
      subcategories: [
        SubCategory(id: 'sub_super', name: 'Supermercat', monthlyBudget: 300),
      ],
    );

    final catEstalvi = const Category(
      id: 'cat_estalvi',
      name: 'Estalvi',
      icon: '💰',
      type: TransactionType.expense,
      subcategories: [
        SubCategory(
          id: 'sub_guardiola',
          name: 'Fons Emergència',
          monthlyBudget: 200,
          linkedSavingsGoalId: 'goal_emergencia',
        ),
      ],
    );

    final catNomina = const Category(
      id: 'cat_nomina',
      name: 'Nòmina',
      icon: '💰',
      type: TransactionType.income,
      subcategories: [
        SubCategory(
          id: 'sub_nomina',
          name: 'Nòmina',
          monthlyBudget: 0,
          isFixed: true,
        ),
      ],
    );

    final categories = [catCura, catCuraOld, catDeute, catAlimentacio, catEstalvi, catNomina];

    final cycles2026 = [
      BillingCycle(
        id: 'c1',
        groupId: 'g1',
        name: 'Gener 2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31, 23, 59, 59),
      ),
      BillingCycle(
        id: 'c2',
        groupId: 'g1',
        name: 'Febrer 2026',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28, 23, 59, 59),
      ),
      BillingCycle(
        id: 'c3',
        groupId: 'g1',
        name: 'Març 2026',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31, 23, 59, 59),
      ),
      BillingCycle(
        id: 'c4',
        groupId: 'g1',
        name: 'Abril 2026',
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30, 23, 59, 59),
      ),
      BillingCycle(
        id: 'c5',
        groupId: 'g1',
        name: 'Maig 2026',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31, 23, 59, 59),
      ),
      // Cicles restants fins a desembre
      ...List.generate(7, (i) {
        final month = i + 6;
        return BillingCycle(
          id: 'c$month',
          groupId: 'g1',
          name: 'Mes $month 2026',
          startDate: DateTime(2026, month, 1),
          endDate: DateTime(2026, month + 1, 0, 23, 59, 59),
        );
      }),
    ];

    final debts = [
      const DebtAccount(
        id: 'debt_hipoteca',
        name: 'Hipoteca CaixaBank',
        currentBalance: 120000,
        originalAmount: 150000,
        interestRate: 2.5,
        monthlyInstallment: 500,
      ),
    ];

    test('Càlcul anual amb despesa real i projecció transparent', () {
      final transactions = [
        // Mes 1: 300€ super, 500€ hipoteca, 100€ negatius
        Transaction(
          id: 't1',
          groupId: 'g1',
          amount: 300,
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Compra Mercadona',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't2',
          groupId: 'g1',
          amount: 500,
          date: DateTime(2026, 1, 15),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_hipoteca',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Quota Hipoteca',
          concept: 'Quota Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't3',
          groupId: 'g1',
          amount: 100,
          date: DateTime(2026, 1, 20),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_negatius',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Negatius comptes a tornar',
          concept: 'Ajust compte',
          isIncome: false,
          payer: 'u1',
        ),
        // Mes 2: 300€ super, 500€ hipoteca, refund de 50€ al supermercat
        Transaction(
          id: 't4',
          groupId: 'g1',
          amount: 300,
          date: DateTime(2026, 2, 5),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Compra Carrefour',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't5',
          groupId: 'g1',
          amount: 50,
          date: DateTime(2026, 2, 6),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Devolució Carrefour',
          isIncome: true, // Refund! Ha de restar
          payer: 'u1',
        ),
        Transaction(
          id: 't6',
          groupId: 'g1',
          amount: 500,
          date: DateTime(2026, 2, 15),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_hipoteca',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Quota Hipoteca',
          concept: 'Quota Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
        // Mes 3: 400€ super, 500€ hipoteca, 200€ aportació guardiola (exclòs!)
        Transaction(
          id: 't7',
          groupId: 'g1',
          amount: 400,
          date: DateTime(2026, 3, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Compra Lidl',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't8',
          groupId: 'g1',
          amount: 500,
          date: DateTime(2026, 3, 15),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_hipoteca',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Quota Hipoteca',
          concept: 'Quota Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't9',
          groupId: 'g1',
          amount: 200,
          date: DateTime(2026, 3, 20),
          categoryId: 'cat_estalvi',
          subCategoryId: 'sub_guardiola',
          categoryName: 'Estalvi',
          subCategoryName: 'Fons Emergència',
          concept: 'Aportació estalvi',
          isIncome: false,
          savingsGoalId: 'goal_emergencia', // Guardiola! Ha de quedar exclòs dels totals
          payer: 'u1',
        ),
        // Ingressos: 2.000€ cada mes (Gen, Feb, Mar)
        Transaction(
          id: 't_inc1',
          groupId: 'g1',
          amount: 2000,
          date: DateTime(2026, 1, 28),
          categoryId: 'cat_nomina',
          subCategoryId: 'sub_nomina',
          categoryName: 'Nòmina',
          subCategoryName: 'Nòmina',
          concept: 'Nòmina Gener',
          isIncome: true,
          payer: 'u1',
        ),
        Transaction(
          id: 't_inc2',
          groupId: 'g1',
          amount: 2000,
          date: DateTime(2026, 2, 28),
          categoryId: 'cat_nomina',
          subCategoryId: 'sub_nomina',
          categoryName: 'Nòmina',
          subCategoryName: 'Nòmina',
          concept: 'Nòmina Febrer',
          isIncome: true,
          payer: 'u1',
        ),
        Transaction(
          id: 't_inc3',
          groupId: 'g1',
          amount: 2000,
          date: DateTime(2026, 3, 28),
          categoryId: 'cat_nomina',
          subCategoryId: 'sub_nomina',
          categoryName: 'Nòmina',
          subCategoryName: 'Nòmina',
          concept: 'Nòmina Març',
          isIncome: true,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      // Verificacions de cicles
      expect(report.completedCyclesCount, 3);
      expect(report.remainingCyclesCount, 9);
      expect(report.totalCyclesInYear, 12);

      // Ingressos reals dels 3 mesos: 2.000 x 3 = 6.000€
      expect(report.totalRealIncome, 6000.0);
      expect(report.monthlyAverageIncome, 2000.0);
      // Ingressos projectats anuals: 6.000 + (2.000 * 9) = 24.000€
      expect(report.projectedAnnualIncome, 24000.0);

      // Despeses reals dels 3 mesos:
      // Mes 1: 300 (super) + 500 (hipoteca) + 100 (negatius) = 900€
      // Mes 2: 250 (super net: 300 - 50) + 500 (hipoteca) = 750€
      // Mes 3: 400 (super) + 500 (hipoteca) + 0 (guardiola) = 900€
      // Total Real = 900 + 750 + 900 = 2.550 €
      expect(report.totalRealExpense, 2550.0);

      // Mitjana mensual despesa: 2.550 / 3 = 850 €/mes
      expect(report.monthlyAverageExpense, 850.0);

      // Projecció anual despesa: 2.550 + (850 * 9) = 10.200 €
      expect(report.projectedAnnualExpense, 10200.0);

      // Diferencial net anual: 24.000 (ingressos) - 10.200 (despeses) = +13.800 €
      expect(report.netAnnualDifference, 13800.0);
      expect(report.monthlyNetDifference, 1150.0);

      // Servei de Deute Bancari:
      // Quota hipoteca = 500€ x 3 mesos = 1.500€ real
      // Negatius comptes a tornar (100€) NO ha de sumar com a deute bancari!
      // Mitjana mensual deute = 500€/mes -> Total anual deute = 500 * 12 = 6.000€
      expect(report.debtServiceAnnualTotal, 6000.0);
      expect(report.debtServiceMonthlyAverage, 500.0);
      // % servei de deute: 6.000 / 10.200 = 58.82%
      expect((report.debtServicePercentage * 100).toStringAsFixed(1), '58.8');
    });

    test('Consolidació de categories fusionades ("Cura Personal / Mascotes" -> "Cura Personal")', () {
      final transactions = [
        Transaction(
          id: 'tx_c1',
          groupId: 'g1',
          amount: 80,
          date: DateTime(2026, 1, 12),
          categoryId: 'cat_cura_old', // Categoria fusionada antiga
          subCategoryId: 'sub_cura_old',
          categoryName: 'Cura Personal / Mascotes',
          subCategoryName: 'Veterinari',
          concept: 'Vacuna gos',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 'tx_c2',
          groupId: 'g1',
          amount: 40,
          date: DateTime(2026, 2, 14),
          categoryId: 'cat_cura', // Categoria activa
          subCategoryId: 'sub_cura_general',
          categoryName: 'Cura Personal',
          subCategoryName: 'General',
          concept: 'Farmàcia',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      // Comprovar que només hi ha 1 categoria consolidada per a Cura Personal
      final curaCats = report.categories.where(
        (c) => c.categoryName.toLowerCase().contains('cura personal'),
      ).toList();

      expect(curaCats.length, 1);
      final cura = curaCats.first;
      expect(cura.categoryName, 'Cura Personal');
      // Real: 80 + 40 = 120€ en 3 mesos -> 40€/mes -> 480€ anual
      expect(cura.realSpent, 120.0);
      expect(cura.monthlyAverage, 40.0);
      expect(cura.projectedAnnualTotal, 480.0);
    });

    test('Generació de resum executiu i format CSV per al banc', () {
      final transactions = [
        Transaction(
          id: 't1',
          groupId: 'g1',
          amount: 300,
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Super',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      final summary = AnnualReportService.generateExecutiveSummary(report);
      expect(summary, contains('VISTA ANUAL (2026)'));
      expect(summary, contains('SERVEI DE DEUTE BANCARI'));
      expect(summary, contains('DESGLOSSAMENT PER CATEGORIES'));

      final csv = AnnualReportService.exportToCsv(report);
      expect(csv, contains('Any;Tipus;Categoria;Subcategoria;Despesa Real;Mitjana Mensual;Total Anual;Percentatge'));
      expect(csv, contains('2026;TOTAL;Despesa Anual Total'));
      expect(csv, contains('2026;INGRESSOS;Ingressos de la Llar'));
      expect(csv, contains('2026;DIFERENCIAL;Diferencial Net'));
    });

    test('Any anterior amb dades insuficients (< 3 mesos) no genera percentatges de variació', () {
      final transactions = [
        // 2026: 3 mesos complets
        Transaction(
          id: 't2026_1',
          groupId: 'g1',
          amount: 300,
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Super 2026',
          isIncome: false,
          payer: 'u1',
        ),
        // 2025: només 1 transacció aïllada al desembre (sense dades comparables)
        Transaction(
          id: 't2025_1',
          groupId: 'g1',
          amount: 5,
          date: DateTime(2025, 12, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Test 2025',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      // Com que 2025 només té 1 mes de dades, no és comparable
      expect(report.hasPreviousYearData, false);
      final menjar = report.categories.firstWhere((c) => c.categoryId == 'cat_menjar');
      expect(menjar.yearOverYearDelta, isNull);
      expect(menjar.previousYearAnnualTotal, isNull);
    });

    test('Generació de document PDF oficial per al banc', () async {
      final transactions = [
        Transaction(
          id: 't1',
          groupId: 'g1',
          amount: 300,
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Super',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      final pdfBytes = await AnnualReportPdfService.generatePdf(report);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Unificació de categories desconegudes/orfes i neteja de noms "(antic)"', () {
      final transactions = [
        // Dues transaccions amb categories orfes desconegudes diferents (ex. 64€ i 59€)
        Transaction(
          id: 't_unk1',
          groupId: 'g1',
          amount: 64,
          date: DateTime(2026, 1, 15),
          categoryId: 'cat_orfe_1',
          subCategoryId: 'sub_1',
          categoryName: 'Categoria desconeguda',
          subCategoryName: 'Altres (antic)', // Ha de netejar-se a 'Altres'
          concept: 'Despesa solta 1',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_unk2',
          groupId: 'g1',
          amount: 59,
          date: DateTime(2026, 2, 20),
          categoryId: 'cat_orfe_2',
          subCategoryId: 'sub_2',
          categoryName: 'Categoria desconeguda',
          subCategoryName: 'Despeses (arxivat)', // Ha de netejar-se a 'Despeses'
          concept: 'Despesa solta 2',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      // Comprovar que NO hi ha categories anomenades 'Categoria desconeguda'
      expect(report.categories.any((c) => c.categoryName.toLowerCase().contains('desconeguda')), false);

      // Comprovar que s'han unificat sota 'Altres (sense classificar)'
      final unclassified = report.categories.firstWhere((c) => c.categoryId == AnnualReportService.kUnclassifiedCategoryId);
      expect(unclassified.categoryName, 'Altres (sense classificar)');
      // Real: 64 + 59 = 123€ en 3 mesos -> 41€/mes -> 492€ anual
      expect(unclassified.realSpent, 123.0);
      expect(unclassified.monthlyAverage, 41.0);

      // Comprovar que els noms de les subcategories estan nets
      final subNames = unclassified.subcategories.map((s) => s.name).toList();
      expect(subNames, contains('Altres'));
      expect(subNames, contains('Despeses'));
      expect(subNames.any((n) => n.contains('(antic)')), false);
      expect(subNames.any((n) => n.contains('(arxivat)')), false);
    });

    test('Invariants exhaustius en mode Real i Projecció per a TOTES les categories i subcategories', () {
      final transactions = [
        Transaction(
          id: 't_m1',
          groupId: 'g1',
          amount: 450,
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Super 1',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_m2',
          groupId: 'g1',
          amount: 300,
          date: DateTime(2026, 2, 10),
          categoryId: 'cat_menjar',
          subCategoryId: 'sub_super',
          categoryName: 'Alimentació',
          subCategoryName: 'Supermercat',
          concept: 'Super 2',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_c1',
          groupId: 'g1',
          amount: 150,
          date: DateTime(2026, 1, 15),
          categoryId: 'cat_cura',
          subCategoryId: 'sub_cura_general',
          categoryName: 'Cura Personal',
          subCategoryName: 'General',
          concept: 'Farmàcia',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_c2',
          groupId: 'g1',
          amount: 90,
          date: DateTime(2026, 3, 12),
          categoryId: 'cat_cura',
          subCategoryId: 'sub_mascotes',
          categoryName: 'Cura Personal',
          subCategoryName: 'Mascotes',
          concept: 'Pinso',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_d1',
          groupId: 'g1',
          amount: 600,
          date: DateTime(2026, 1, 5),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_hipoteca',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Quota Hipoteca',
          concept: 'Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_d2',
          groupId: 'g1',
          amount: 600,
          date: DateTime(2026, 2, 5),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_hipoteca',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Quota Hipoteca',
          concept: 'Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_d3',
          groupId: 'g1',
          amount: 600,
          date: DateTime(2026, 3, 5),
          categoryId: 'cat_deute',
          subCategoryId: 'sub_hipoteca',
          categoryName: 'Préstecs i Crèdits',
          subCategoryName: 'Quota Hipoteca',
          concept: 'Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now, // 3 cicles complets
      );

      expect(report.completedCyclesCount, 3);
      expect(report.totalCyclesInYear, 12);
      expect(report.periodStartDate, isNotNull);
      expect(report.periodEndDate, isNotNull);

      // Invariant 1: suma(categories.realSpent) == totalRealExpense
      final sumCatReal = report.categories.fold<double>(0, (acc, c) => acc + c.realSpent);
      expect((sumCatReal - report.totalRealExpense).abs() < 1e-5, isTrue);

      // Invariant 2: suma(categories.projectedAnnualTotal) == projectedAnnualExpense
      final sumCatProj = report.categories.fold<double>(0, (acc, c) => acc + c.projectedAnnualTotal);
      expect((sumCatProj - report.projectedAnnualExpense).abs() < 1e-5, isTrue);

      for (final cat in report.categories) {
        // Invariant 3: suma(subcategories.realSpent) == category.realSpent
        final sumSubReal = cat.subcategories.fold<double>(0, (acc, s) => acc + s.realSpent);
        expect((sumSubReal - cat.realSpent).abs() < 1e-5, isTrue);

        // Invariant 4: suma(subcategories.projectedAnnualTotal) == category.projectedAnnualTotal
        final sumSubProj = cat.subcategories.fold<double>(0, (acc, s) => acc + s.projectedAnnualTotal);
        expect((sumSubProj - cat.projectedAnnualTotal).abs() < 1e-5, isTrue);

        // Invariant 5: real * 12 / cicles_complets == projecció
        final expectedProj = (cat.realSpent * 12) / report.completedCyclesCount;
        expect((expectedProj - cat.projectedAnnualTotal).abs() < 1e-5, isTrue);

        // Invariant 6: el €/mes és idèntic en totes dues bases
        expect(cat.monthlyAverage, cat.realSpent / report.completedCyclesCount);

        for (final sub in cat.subcategories) {
          final expectedSubProj = (sub.realSpent * 12) / report.completedCyclesCount;
          expect((expectedSubProj - sub.projectedAnnualTotal).abs() < 1e-5, isTrue);
          expect(sub.monthlyAverage, sub.realSpent / report.completedCyclesCount);
        }
      }

      // Invariant 7: suma dels percentatges crus de categories == 1.0 (amb tolerància 1e-6)
      final rawCatPercentages = report.categories.map((c) => c.percentageOfTotal).toList();
      final sumRawCatPct = rawCatPercentages.fold<double>(0, (acc, p) => acc + p);
      expect((sumRawCatPct - 1.0).abs() < 1e-6, isTrue);
    });

    test('Largest Remainder Method garanteix que els percentatges sumen exactament 100', () {
      final values = [47.3, 27.4, 17.8, 7.5];
      final ints = AnnualReportService.largestRemainderPercentages(values, targetSum: 100);

      expect(ints.fold<int>(0, (sum, v) => sum + v), 100);
      expect(ints, [47, 27, 18, 8]);
    });

    test('Cas límit: 0 cicles complets no genera divisions per zero', () {
      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: [],
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: DateTime(2026, 1, 1), // Abans del tancament de gener -> 0 cicles
      );

      expect(report.completedCyclesCount, 0);
      expect(report.monthlyAverageExpense, 0.0);
      expect(report.projectedAnnualExpense, 0.0);
      expect(report.monthlyAverageIncome, 0.0);
      expect(report.projectedAnnualIncome, 0.0);
    });

    test('Diferencial Estructural (Nòmines) vs Diferencial de Tresoreria (Nòmines + Bizums)', () {
      final catNomina = const Category(
        id: 'cat_nomina',
        name: 'Nòmina',
        icon: '💰',
        type: TransactionType.income,
        subcategories: [
          SubCategory(id: 'sub_eloi', name: 'Eloi', monthlyBudget: 0, isFixed: true),
        ],
      );

      final catBizum = const Category(
        id: 'cat_altres_inc',
        name: 'Ingressos',
        icon: '🏠',
        type: TransactionType.income,
        subcategories: [
          SubCategory(id: 'sub_bizum', name: 'Bizum', monthlyBudget: 0, isFixed: false),
        ],
      );

      final transactions = [
        // 3 mesos de Nòmina d'Eloi: 2.500 € / mes = 7.500 € reals
        Transaction(
          id: 't_inc1',
          groupId: 'g1',
          amount: 2500,
          concept: 'Nòmina Gener',
          date: DateTime(2026, 1, 30),
          categoryId: 'cat_nomina',
          categoryName: 'Nòmina',
          subCategoryId: 'sub_eloi',
          subCategoryName: 'Eloi',
          isIncome: true,
          payer: 'u1',
        ),
        Transaction(
          id: 't_inc2',
          groupId: 'g1',
          amount: 2500,
          concept: 'Nòmina Febrer',
          date: DateTime(2026, 2, 28),
          categoryId: 'cat_nomina',
          categoryName: 'Nòmina',
          subCategoryId: 'sub_eloi',
          subCategoryName: 'Eloi',
          isIncome: true,
          payer: 'u1',
        ),
        Transaction(
          id: 't_inc3',
          groupId: 'g1',
          amount: 2500,
          concept: 'Nòmina Març',
          date: DateTime(2026, 3, 31),
          categoryId: 'cat_nomina',
          categoryName: 'Nòmina',
          subCategoryId: 'sub_eloi',
          subCategoryName: 'Eloi',
          isIncome: true,
          payer: 'u1',
        ),
        // 1 Bizum puntual de 600 € al febrer
        Transaction(
          id: 't_bizum',
          groupId: 'g1',
          amount: 600,
          concept: 'Bizum Viatge',
          date: DateTime(2026, 2, 15),
          categoryId: 'cat_altres_inc',
          categoryName: 'Ingressos',
          subCategoryId: 'sub_bizum',
          subCategoryName: 'Bizum',
          isIncome: true,
          payer: 'u1',
        ),
        // 3 mesos de Despesa Super: 3.500 € / mes = 10.500 € reals
        Transaction(
          id: 't_exp1',
          groupId: 'g1',
          amount: 3500,
          concept: 'Super Gener',
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_menjar',
          categoryName: 'Alimentació',
          subCategoryId: 'sub_super',
          subCategoryName: 'Supermercat',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_exp2',
          groupId: 'g1',
          amount: 3500,
          concept: 'Super Febrer',
          date: DateTime(2026, 2, 10),
          categoryId: 'cat_menjar',
          categoryName: 'Alimentació',
          subCategoryId: 'sub_super',
          subCategoryName: 'Supermercat',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't_exp3',
          groupId: 'g1',
          amount: 3500,
          concept: 'Super Març',
          date: DateTime(2026, 3, 10),
          categoryId: 'cat_menjar',
          categoryName: 'Alimentació',
          subCategoryId: 'sub_super',
          subCategoryName: 'Supermercat',
          isIncome: false,
          payer: 'u1',
        ),
      ];

      final testCats = [...categories, catNomina, catBizum];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: testCats,
        cycles: cycles2026,
        debts: debts,
        currentDate: now, // 3 cicles complets
      );

      // Reals
      expect(report.totalRealRecurringIncome, 7500.0);
      expect(report.totalRealVariableIncome, 600.0);
      expect(report.totalRealIncome, 8100.0);
      expect(report.totalRealExpense, 10500.0);

      // Projecció
      // Nòmina anualitzada: 2.500 * 12 = 30.000 €
      expect(report.projectedAnnualRecurringIncome, 30000.0);
      // Bizums no s'inflen pel futur: 600 €
      expect(report.projectedAnnualVariableIncome, 600.0);
      // Total Ingressos Estimats: 30.000 + 600 = 30.600 € (MAI (8100/3)*12 = 32.400 €)
      expect(report.projectedAnnualIncome, 30600.0);
      // Despesa anualitzada: 3.500 * 12 = 42.000 €
      expect(report.projectedAnnualExpense, 42000.0);

      // Diferencial Estructural: 30.000 - 42.000 = -12.000 €
      expect(report.netStructuralDifference, -12000.0);
      // Diferencial de Tresoreria: 30.600 - 42.000 = -11.400 €
      expect(report.netAnnualDifference, -11400.0);
    });

    test('Invariant de Despesa Real: suma(cat.realSpent) == totalRealExpense i PDF coherent en Real', () async {
      final transactions = [
        Transaction(
          id: 't1',
          groupId: 'g1',
          amount: 13864,
          concept: 'Quota Hipoteca',
          date: DateTime(2026, 1, 10),
          categoryId: 'cat_deute',
          categoryName: 'Préstecs i Crèdits',
          subCategoryId: 'sub_hipoteca',
          subCategoryName: 'Quota Hipoteca',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't2',
          groupId: 'g1',
          amount: 4042,
          concept: 'Masia',
          date: DateTime(2026, 2, 10),
          categoryId: 'cat_cura',
          categoryName: 'Cura Personal',
          subCategoryId: 'sub_cura_general',
          subCategoryName: 'General',
          isIncome: false,
          payer: 'u1',
        ),
        Transaction(
          id: 't3',
          groupId: 'g1',
          amount: 2930,
          concept: 'Supermercat',
          date: DateTime(2026, 3, 10),
          categoryId: 'cat_menjar',
          categoryName: 'Alimentació',
          subCategoryId: 'sub_super',
          subCategoryName: 'Supermercat',
          isIncome: false,
          payer: 'u1',
        ),
        // Ingrés sense categoria (orfe)
        Transaction(
          id: 't4',
          groupId: 'g1',
          amount: 121,
          concept: 'Ingrés orfe',
          date: DateTime(2026, 3, 15),
          categoryId: '',
          categoryName: '',
          subCategoryId: '',
          subCategoryName: '',
          isIncome: true,
          payer: 'u1',
        ),
      ];

      final report = AnnualReportService.calculateAnnualReport(
        targetYear: 2026,
        transactions: transactions,
        categories: categories,
        cycles: cycles2026,
        debts: debts,
        currentDate: now,
      );

      // Invariant: La suma de realSpent de totes les categories és exactament igual a totalRealExpense
      final sumRealSpent = report.categories.fold(0.0, (sum, c) => sum + c.realSpent);
      expect(sumRealSpent, equals(report.totalRealExpense));
      expect(report.totalRealExpense, equals(20836.0));

      // L'ingrés orfe s'agrupa sota "Altres (sense classificar)"
      final unclassifiedIncome = report.incomeCategories.firstWhere((c) => c.categoryId == AnnualReportService.kUnclassifiedCategoryId);
      expect(unclassifiedIncome.categoryName, equals('Altres (sense classificar)'));
      expect(unclassifiedIncome.realSpent, equals(121.0));

      // Generació del document PDF
      final pdfBytes = await AnnualReportPdfService.generatePdf(report);
      expect(pdfBytes, isNotEmpty);
    });
  });
}
