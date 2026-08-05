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
      savedThisCycle: (json['savedThisCycle'] as num?)?.toDouble() ?? 0.0,
      withdrawnThisCycle:
          (json['withdrawnThisCycle'] as num?)?.toDouble() ?? 0.0,
      netSaved: (json['netSaved'] as num?)?.toDouble() ?? 0.0,
      personalTransferIncome:
          (json['personalTransferIncome'] as num?)?.toDouble() ?? 0.0,
      topOverspent: (json['topOverspent'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      topSaved: (json['topSaved'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      zeroExpenseDays: (json['zeroExpenseDays'] as num?)?.toInt() ?? 0,
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      unexpectedExpenses: (json['unexpectedExpenses'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      generatedForStartDate: json['generatedForStartDate'] == null
          ? null
          : DateTime.parse(json['generatedForStartDate'] as String),
      generatedForEndDate: json['generatedForEndDate'] == null
          ? null
          : DateTime.parse(json['generatedForEndDate'] as String),
      sourceFingerprint: json['sourceFingerprint'] as String? ?? '',
      reportSchemaVersion: (json['reportSchemaVersion'] as num?)?.toInt() ?? 0,
      ledgerSchemaVersion: (json['ledgerSchemaVersion'] as num?)?.toInt() ?? 0,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
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
      'savedThisCycle': instance.savedThisCycle,
      'withdrawnThisCycle': instance.withdrawnThisCycle,
      'netSaved': instance.netSaved,
      'personalTransferIncome': instance.personalTransferIncome,
      'topOverspent': instance.topOverspent,
      'topSaved': instance.topSaved,
      'zeroExpenseDays': instance.zeroExpenseDays,
      'totalDays': instance.totalDays,
      'unexpectedExpenses': instance.unexpectedExpenses,
      'generatedForStartDate':
          instance.generatedForStartDate?.toIso8601String(),
      'generatedForEndDate': instance.generatedForEndDate?.toIso8601String(),
      'sourceFingerprint': instance.sourceFingerprint,
      'reportSchemaVersion': instance.reportSchemaVersion,
      'ledgerSchemaVersion': instance.ledgerSchemaVersion,
      'schemaVersion': instance.schemaVersion,
    };
