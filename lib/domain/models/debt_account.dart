import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_account.freezed.dart';
part 'debt_account.g.dart';

@freezed
class DebtAccount with _$DebtAccount {
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
}
