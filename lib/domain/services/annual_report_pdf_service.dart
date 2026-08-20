import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/annual_report.dart';

class AnnualReportPdfService {
  /// Genera el document PDF d'informe anual en format A4
  static Future<Uint8List> generatePdf(AnnualReportData data) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'ca_ES', symbol: 'EUR ', decimalDigits: 0);
    final pctFormat = NumberFormat.percentPattern('ca_ES');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = dateFormat.format(DateTime.now());

    final diff = data.netRealDifference;
    final diffIsNegative = diff < 0;
    final diffSign = diff >= 0 ? '+' : '-';

    // Text del període per a capçalera i footer
    final periodString = (data.periodStartDate != null && data.periodEndDate != null)
        ? '${dateFormat.format(data.periodStartDate!)} - ${dateFormat.format(data.periodEndDate!)}'
        : 'Exercici ${data.year}';
    final periodFooter = 'Despesa real $periodString (${data.completedCyclesCount} cicles complets)';

    // Categories principals per al gràfic de barres (fins a 8) ordenades per despesa real
    final topCategories = List<AnnualCategoryData>.from(data.categories)
      ..sort((a, b) => b.realSpent.compareTo(a.realSpent));
    final displayTop = topCategories.take(8).toList();
    final maxCategoryAmount = displayTop.isNotEmpty
        ? displayTop.first.realSpent
        : 1.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                periodFooter,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                'Pàgina ${context.pageNumber} de ${context.pagesCount}  ·  Cèntim',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (context) => [
          // 1. Capçalera
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CÈNTIM · INFORME ECONÒMIC REAL',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Despesa real $periodString (${data.completedCyclesCount} cicles complets)',
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Data d\'emissió: $today',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                  pw.Text(
                    'Document per a ús bancari i planificació',
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 4),

          // 2. Nota metodològica del període
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              'Període auditat: $periodString (${data.completedCyclesCount} cicles tancats amb moviments reals).'
              '${data.remainingCyclesCount > 0 ? " Equivalent anualitzat (estimació): ${currency.format(data.projectedAnnualExpense)}" : ""}',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
            ),
          ),
          pw.SizedBox(height: 10),

          // 3. BLOC DE BALANÇ DE LA LLAR (Ingressos vs Despeses vs Diferencial)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CAPACITAT ECONÒMICA I BALANÇ DE LA LLAR (${data.year})',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Ingressos
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INGRESSOS DE LA LLAR (${data.completedCyclesCount} cicles)',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            currency.format(data.totalRealRecurringIncome),
                            style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                          pw.Text(
                            'Nòmines: ${currency.format(data.monthlyAverageRecurringIncome)}/mes',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                          ),
                          if (data.totalRealVariableIncome > 0)
                            pw.Text(
                              '+${currency.format(data.totalRealVariableIncome)} puntuals (Total: ${currency.format(data.totalRealIncome)})',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                            ),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 42, color: PdfColors.grey300),
                    pw.SizedBox(width: 10),

                    // Despeses
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DESPESA REAL TOTAL (${data.completedCyclesCount} cicles)',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            currency.format(data.totalRealExpense),
                            style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                          pw.Text(
                            '${currency.format(data.monthlyAverageExpense)} / mes',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(width: 1, height: 42, color: PdfColors.grey300),
                    pw.SizedBox(width: 10),

                    // Diferencial Estructural (PRINCIPAL) + Tresoreria (SECUNDARI)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DIFERENCIAL ESTRUCTURAL',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          () {
                            final structDiff = data.netRealStructuralDifference;
                            final isNeg = structDiff < 0;
                            final sign = structDiff >= 0 ? '+' : '-';
                            return pw.Text(
                              '$sign${currency.format(structDiff.abs())}',
                              style: pw.TextStyle(
                                fontSize: 12.5,
                                fontWeight: pw.FontWeight.bold,
                                color: isNeg ? PdfColors.red800 : PdfColors.green800,
                              ),
                            );
                          }(),
                          () {
                            final structDiff = data.netRealStructuralDifference;
                            final sign = structDiff >= 0 ? '+' : '-';
                            final monthly = data.completedCyclesCount > 0 ? (structDiff / data.completedCyclesCount).abs() : 0.0;
                            return pw.Text(
                              '$sign${currency.format(monthly)} / mes',
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                            );
                          }(),
                          pw.Text(
                            'Tresoreria: ${diffSign}${currency.format(diff.abs())}',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // 4. Blocs Detall: Despesa Real/Projecció i Servei de Deute Bancari
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bloc 1: Despesa i Projecció
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(9),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ESTRUCTURA DE LA DESPESA',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '- Real acumulat (${data.completedCyclesCount}m): ${currency.format(data.totalRealExpense)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      ),
                      if (data.remainingCyclesCount > 0)
                        pw.Text(
                          '- Projecció restant (${data.remainingCyclesCount}m): ${currency.format(data.projectedAnnualExpense - data.totalRealExpense)}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Bloc 2: Servei de Deute Bancari
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(9),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SERVEI DE DEUTE BANCARI',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 3),
                      () {
                        final realDebt = data.debtServiceMonthlyAverage * data.completedCyclesCount;
                        final realDebtPct = data.totalRealExpense > 0 ? (realDebt / data.totalRealExpense) * 100 : 0.0;
                        return pw.Text(
                          '${currency.format(realDebt)} real (${currency.format(data.debtServiceMonthlyAverage)} / mes · ${realDebtPct.toStringAsFixed(1)}% despesa)',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        );
                      }(),
                      pw.Text(
                        'Préstecs i crèdits financers. Exclou regularitzacions internes.',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Bloc 3: Moviments de Guardioles / Estalvi (fora dels totals de despesa)
          if (data.totalRealSavingsDeposits > 0 || data.totalRealSavingsWithdrawals > 0) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MOVIMENTS DE GUARDIÒLES I ESTALVI (${data.completedCyclesCount} cicles)',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Aportacions: +${currency.format(data.totalRealSavingsDeposits)} (${data.totalRealSavingsDepositsCount} mov.)  ·  Retirades: -${currency.format(data.totalRealSavingsWithdrawals)} (${data.totalRealSavingsWithdrawalsCount} mov.)',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Estalvi Net: ${data.netSavings >= 0 ? "+" : "-"}${currency.format(data.netSavings.abs())}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: data.netSavings < 0 ? PdfColors.red800 : PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Retornat: ${data.savingsReturnedPercentage.toStringAsFixed(0)}%',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
          ],

          // 5. GRÀFIC DE BARRES HORITZONTALS (Top 8 Categories reals)
          if (displayTop.isNotEmpty) ...[
            pw.Text(
              'DISTRIBUCIÓ DE LES PRINCIPALS CATEGORIES (DESPESA REAL)',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                children: [
                  for (final cat in displayTop) ...[
                    () {
                      final factor = maxCategoryAmount > 0
                          ? (cat.realSpent / maxCategoryAmount).clamp(0.02, 1.0)
                          : 0.02;
                      final filledFlex = (factor * 1000).round().clamp(20, 1000);
                      final emptyFlex = (1000 - filledFlex).clamp(0, 980);
                      final realPct = data.totalRealExpense > 0
                          ? (cat.realSpent / data.totalRealExpense)
                          : 0.0;

                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 120,
                              child: pw.Text(
                                cat.categoryName,
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                                overflow: pw.TextOverflow.clip,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                height: 7,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Expanded(
                                      flex: filledFlex,
                                      child: pw.Container(
                                        height: 7,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColors.grey700,
                                          borderRadius: pw.BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    if (emptyFlex > 0)
                                      pw.Expanded(
                                        flex: emptyFlex,
                                        child: pw.Container(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.SizedBox(
                              width: 95,
                              child: pw.Text(
                                '${currency.format(cat.realSpent)} (${(realPct * 100).toStringAsFixed(1)}%)',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }(),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // 6. TAULA DE DESGLOSSAMENT DETALLADA PER CATEGORIES I SUBCATEGORIES
          pw.Text(
            'DESGLOSSAMENT COMPLET PER CATEGORIA I SUBCATEGORIA',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.SizedBox(height: 4),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),   // Concepte / Categoria
              1: pw.FlexColumnWidth(2),   // Real
              2: pw.FlexColumnWidth(2),   // Mitjana mensual
              3: pw.FlexColumnWidth(2.5), // Total anual
              4: pw.FlexColumnWidth(1.5), // % total
            },
            children: [
              // Capçalera taula
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeaderCell('Categoria / Subcategoria'),
                  _tableHeaderCell('Real (${data.completedCyclesCount}m)', align: pw.TextAlign.right),
                  _tableHeaderCell('EUR / mes', align: pw.TextAlign.right),
                  _tableHeaderCell('Total Anual', align: pw.TextAlign.right),
                  _tableHeaderCell('% Total', align: pw.TextAlign.right),
                ],
              ),

              // Categories i subcategories desplegades
              for (final cat in data.categories) ...[
                // Fila de Categoria Principal
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableCell(cat.categoryName.toUpperCase(), isBold: true),
                    _tableCell(currency.format(cat.realSpent), isBold: true, align: pw.TextAlign.right),
                    _tableCell(currency.format(cat.monthlyAverage), isBold: true, align: pw.TextAlign.right),
                    _tableCell(currency.format(cat.projectedAnnualTotal), isBold: true, align: pw.TextAlign.right),
                    _tableCell(pctFormat.format(cat.percentageOfTotal), isBold: true, align: pw.TextAlign.right),
                  ],
                ),

                // Files de Subcategories
                for (final sub in cat.subcategories)
                  pw.TableRow(
                    children: [
                      _tableCell('   - ${sub.name}', fontSize: 8),
                      _tableCell(currency.format(sub.realSpent), fontSize: 8, align: pw.TextAlign.right),
                      _tableCell(currency.format(sub.monthlyAverage), fontSize: 8, align: pw.TextAlign.right),
                      _tableCell(currency.format(sub.projectedAnnualTotal), fontSize: 8, align: pw.TextAlign.right),
                      _tableCell('${(sub.percentageOfCategory * 100).toStringAsFixed(0)}% cat', fontSize: 8, align: pw.TextAlign.right),
                    ],
                  ),
              ],

              // Fila Total
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _tableCell('TOTAL DESPESA ANUAL', isBold: true, fontSize: 9.5),
                  _tableCell(currency.format(data.totalRealExpense), isBold: true, fontSize: 9.5, align: pw.TextAlign.right),
                  _tableCell(currency.format(data.monthlyAverageExpense), isBold: true, fontSize: 9.5, align: pw.TextAlign.right),
                  _tableCell(currency.format(data.projectedAnnualExpense), isBold: true, fontSize: 9.5, align: pw.TextAlign.right),
                  _tableCell('100,0%', isBold: true, fontSize: 9.5, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Comparteix o imprimeix directament el document PDF
  static Future<void> shareOrPrintPdf(AnnualReportData data) async {
    final bytes = await generatePdf(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Centim_Informe_Anual_${data.year}.pdf',
    );
  }

  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isBold = false,
    double fontSize = 8.5,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
