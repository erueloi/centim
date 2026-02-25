import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/debt_account.dart';

class AmortizationDialog extends StatefulWidget {
  final DebtAccount debt;
  final Function(double) onApply;

  const AmortizationDialog({
    super.key,
    required this.debt,
    required this.onApply,
  });

  @override
  State<AmortizationDialog> createState() => _AmortizationDialogState();
}

class _AmortizationDialogState extends State<AmortizationDialog> {
  final _amountController = TextEditingController();
  double _extraPayment = 0.0;

  // Calculation results
  int _originalMonths = 0;
  int _newMonths = 0;
  double _originalInterest = 0.0;
  double _newInterest = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateAmortization();
    _amountController.addListener(() {
      setState(() {
        _extraPayment = double.tryParse(_amountController.text) ?? 0.0;
        _calculateAmortization();
      });
    });
  }

  void _calculateAmortization() {
    if (widget.debt.monthlyInstallment <= 0 ||
        widget.debt.interestRate <= 0 ||
        widget.debt.currentBalance <= 0) {
      return;
    }

    final monthlyRate = widget.debt.interestRate / 100 / 12;

    // ORIGINAL SCENARIO
    _originalMonths = _solveNPer(
      monthlyRate,
      -widget.debt.monthlyInstallment,
      widget.debt.currentBalance,
    );
    _originalInterest = (_originalMonths * widget.debt.monthlyInstallment) -
        widget.debt.currentBalance;

    // NEW SCENARIO (With extra payment upfront)
    final newBalance = widget.debt.currentBalance - _extraPayment;
    if (newBalance <= 0) {
      _newMonths = 0;
      _newInterest = 0;
    } else {
      _newMonths = _solveNPer(
        monthlyRate,
        -widget.debt.monthlyInstallment,
        newBalance,
      );
      _newInterest = (_newMonths * widget.debt.monthlyInstallment) - newBalance;
    }
  }

  /// Calculates number of periods (months) to pay off loan
  /// Formula derived from annuity formula for N
  int _solveNPer(double rate, double pmt, double pv) {
    if (rate == 0) return (pv / -pmt).ceil();
    // N = -log(1 - (rate * PV) / -PMT) / log(1 + rate)
    try {
      final numerator = -pmt;
      final copyPv = pv;
      // If payment is too low to cover interest, it never ends
      if (copyPv * rate >= numerator) return 999;

      // Using simpler approximation loop if formula is complex in Dart math
      // Or proper formula:
      // n = - ( ln(1 - (r*PV / PMT)) / ln(1+r) )
      // Note: PMT in formula is usually positive for payment, but Excel uses sign convention.
      // Let's use loop for safety and simplicity in this context
      double balance = pv;
      int months = 0;
      while (balance > 0 && months < 1000) {
        final interest = balance * rate;
        final principal = -pmt - interest;
        balance -= principal;
        months++;
      }
      return months;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildAmortizationTable() {
    final monthlyRate = widget.debt.interestRate / 100 / 12;
    final balance = widget.debt.currentBalance - _extraPayment;
    final pmt = widget.debt.monthlyInstallment;

    final rows = <DataRow>[];
    double remainingBalance = balance > 0 ? balance : 0;
    int month = 0;
    double totalInterest = 0;
    double totalPrincipal = 0;

    while (remainingBalance > 0.01 && month < 1000) {
      month++;
      final interest = remainingBalance * monthlyRate;
      double principal = pmt - interest;

      // Última quota pot ser menor
      if (principal > remainingBalance) {
        principal = remainingBalance;
      }

      remainingBalance -= principal;
      if (remainingBalance < 0) remainingBalance = 0;

      totalInterest += interest;
      totalPrincipal += principal;

      rows.add(DataRow(
        cells: [
          DataCell(Text('$month', style: const TextStyle(fontSize: 12))),
          DataCell(Text(
            (principal + interest).toStringAsFixed(2),
            style: const TextStyle(fontSize: 12),
          )),
          DataCell(Text(
            principal.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12, color: Colors.green),
          )),
          DataCell(Text(
            interest.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12, color: Colors.red),
          )),
          DataCell(Text(
            remainingBalance.toStringAsFixed(2),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          )),
        ],
      ));
    }

    // Fila de totals
    rows.add(DataRow(
      color: WidgetStateProperty.all(Colors.grey[100]),
      cells: [
        const DataCell(Text('Total',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        DataCell(Text(
          (totalPrincipal + totalInterest).toStringAsFixed(2),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        )),
        DataCell(Text(
          totalPrincipal.toStringAsFixed(2),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
        )),
        DataCell(Text(
          totalInterest.toStringAsFixed(2),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
        )),
        const DataCell(Text('0.00',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    ));

    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 8,
      headingRowHeight: 36,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 36,
      columns: const [
        DataColumn(
            label: Text('Mes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataColumn(
            label: Text('Quota',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            numeric: true),
        DataColumn(
            label: Text('Capital',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            numeric: true),
        DataColumn(
            label: Text('Interès',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            numeric: true),
        DataColumn(
            label: Text('Saldo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            numeric: true),
      ],
      rows: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthsSaved = (_originalMonths - _newMonths).clamp(0, 1000);
    final interestSaved = (_originalInterest - _newInterest).clamp(
      0.0,
      double.infinity,
    );
    final yearsSaved = (monthsSaved / 12).floor();
    final monthsRemainder = monthsSaved % 12;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.calculate, color: AppTheme.anthracite),
          SizedBox(width: 8),
          Text('Simular Amortització'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quant vols aportar extra?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                suffixText: '€',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.copper, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_extraPayment > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_off, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            yearsSaved > 0
                                ? 'Estalvies $yearsSaved anys i $monthsRemainder mesos!'
                                : 'Estalvies $monthsSaved mesos!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (interestSaved > 0) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.savings, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estalvies ${interestSaved.toStringAsFixed(2)} € en interessos!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // Quadre d'amortització complet
            if (widget.debt.monthlyInstallment > 0 &&
                widget.debt.interestRate > 0 &&
                widget.debt.currentBalance > 0) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.table_chart, color: AppTheme.anthracite),
                title: const Text(
                  'Quadre d\'amortització',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildAmortizationTable(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tancar'),
        ),
      ],
    );
  }
}
