// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CycleReportImpl _$$CycleReportImplFromJson(Map<String, dynamic> json) =>
    _$CycleReportImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      cycleId: json['cycleId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      aiVerdict: json['aiVerdict'] as String,
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      savingsPercentage: (json['savingsPercentage'] as num).toDouble(),
      topOverspent: (json['topOverspent'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      topSaved: (json['topSaved'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CycleReportImplToJson(_$CycleReportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'cycleId': instance.cycleId,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'aiVerdict': instance.aiVerdict,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'savingsPercentage': instance.savingsPercentage,
      'topOverspent': instance.topOverspent,
      'topSaved': instance.topSaved,
    };
