// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetEntryImpl _$$BudgetEntryImplFromJson(Map<String, dynamic> json) =>
    _$BudgetEntryImpl(
      id: json['id'] as String,
      subCategoryId: json['subCategoryId'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$$BudgetEntryImplToJson(_$BudgetEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subCategoryId': instance.subCategoryId,
      'year': instance.year,
      'month': instance.month,
      'amount': instance.amount,
    };
