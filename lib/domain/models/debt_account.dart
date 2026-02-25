import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_account.freezed.dart';
part 'debt_account.g.dart';

@freezed
class DebtAccount with _$DebtAccount {
  const DebtAccount._(); // Custom getters must have a private constructor

  const factory DebtAccount({
    required String id,
    required String name, // ex: 'Préstec Cotxe'
    String? bankName, // ex: 'CaixaBank'
    required double currentBalance, // Capital Pendent
    required double originalAmount, // Capital Inicial
    required double interestRate, // TAE/TIN
    required double monthlyInstallment, // Quota mensual
    DateTime? endDate, // Data venciment
    String? linkedExpenseCategoryId, // Per vincular amb pressupost
  }) = _DebtAccount;

  factory DebtAccount.fromJson(Map<String, dynamic> json) =>
      _$DebtAccountFromJson(json);

  String get remainingTimeText {
    if (currentBalance <= 0) return 'Liquidat';

    // 1. Data exacta si està establerta (prioritat)
    if (endDate != null) {
      final now = DateTime.now();
      final diff = endDate!.difference(now);
      final days = diff.inDays;

      if (days < 0) return 'Vencut';
      if (days < 30) return 'Falten $days dies';

      final months = days ~/ 30;
      if (months < 12) return 'Falten $months mesos';

      final years = months ~/ 12;
      final extraMonths = months % 12;
      if (extraMonths == 0) return 'Falta $years any${years > 1 ? "s" : ""}';
      return 'Falten $years any${years > 1 ? "s" : ""} i $extraMonths mes${extraMonths > 1 ? "os" : ""}';
    }

    // 2. Càlcul estimat per NPER (quotes pendents)
    if (monthlyInstallment <= 0) return 'Sense quota definida';

    final r = interestRate / 100 / 12;
    num remainingMonths = 0;

    if (r == 0) {
      remainingMonths = currentBalance / monthlyInstallment;
    } else {
      final numerator = monthlyInstallment;
      final denominator = monthlyInstallment - (currentBalance * r);
      if (denominator <= 0) return 'Quota insuficient, deute infinit';

      remainingMonths = log(numerator / denominator) / log(1 + r);
    }

    final int months = remainingMonths.ceil();
    if (months == 1) return 'Falta 1 quota aprox.';
    if (months < 12) return 'Falten ~ $months quotes';

    final years = months ~/ 12;
    final extraMonths = months % 12;
    if (extraMonths == 0) return 'Falten ~ $years any${years > 1 ? "s" : ""}';
    return 'Falten ~ $years any${years > 1 ? "s" : ""} i $extraMonths mes${extraMonths > 1 ? "os" : ""}';
  }
}
