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
    _originalInterest =
        (_originalMonths * widget.debt.monthlyInstallment) -
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
