// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DebtAccountImpl _$$DebtAccountImplFromJson(Map<String, dynamic> json) =>
    _$DebtAccountImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      bankName: json['bankName'] as String?,
      currentBalance: (json['currentBalance'] as num).toDouble(),
      originalAmount: (json['originalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      monthlyInstallment: (json['monthlyInstallment'] as num).toDouble(),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      linkedExpenseCategoryId: json['linkedExpenseCategoryId'] as String?,
    );

Map<String, dynamic> _$$DebtAccountImplToJson(_$DebtAccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bankName': instance.bankName,
      'currentBalance': instance.currentBalance,
      'originalAmount': instance.originalAmount,
      'interestRate': instance.interestRate,
      'monthlyInstallment': instance.monthlyInstallment,
      'endDate': instance.endDate?.toIso8601String(),
      'linkedExpenseCategoryId': instance.linkedExpenseCategoryId,
    };
