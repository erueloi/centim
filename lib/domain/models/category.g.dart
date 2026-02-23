// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      type: $enumDecodeNullable(_$TransactionTypeEnumMap, json['type']) ??
          TransactionType.expense,
      order: (json['order'] as num?)?.toInt(),
      color: (json['color'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'subcategories': instance.subcategories,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'order': instance.order,
      'color': instance.color,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
};

_$SubCategoryImpl _$$SubCategoryImplFromJson(Map<String, dynamic> json) =>
    _$SubCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyBudget: (json['monthlyBudget'] as num).toDouble(),
      isFixed: json['isFixed'] as bool? ?? false,
      isWatched: json['isWatched'] as bool? ?? false,
      defaultPayerId: json['defaultPayerId'] as String?,
      paymentDay: (json['paymentDay'] as num?)?.toInt(),
      paymentTiming:
          $enumDecodeNullable(_$PaymentTimingEnumMap, json['paymentTiming']) ??
              PaymentTiming.specificDay,
      linkedSavingsGoalId: json['linkedSavingsGoalId'] as String?,
      linkedDebtId: json['linkedDebtId'] as String?,
    );

Map<String, dynamic> _$$SubCategoryImplToJson(_$SubCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'monthlyBudget': instance.monthlyBudget,
      'isFixed': instance.isFixed,
      'isWatched': instance.isWatched,
      'defaultPayerId': instance.defaultPayerId,
      'paymentDay': instance.paymentDay,
      'paymentTiming': _$PaymentTimingEnumMap[instance.paymentTiming]!,
      'linkedSavingsGoalId': instance.linkedSavingsGoalId,
      'linkedDebtId': instance.linkedDebtId,
    };

const _$PaymentTimingEnumMap = {
  PaymentTiming.specificDay: 'specificDay',
  PaymentTiming.firstBusinessDay: 'firstBusinessDay',
  PaymentTiming.lastBusinessDay: 'lastBusinessDay',
};
