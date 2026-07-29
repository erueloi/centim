// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransferImpl _$$TransferImplFromJson(Map<String, dynamic> json) =>
    _$TransferImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      sourceAssetId: json['sourceAssetId'] as String,
      sourceAssetName: json['sourceAssetName'] as String,
      destinationType: $enumDecode(
          _$TransferDestinationTypeEnumMap, json['destinationType']),
      destinationId: json['destinationId'] as String,
      destinationName: json['destinationName'] as String,
      note: json['note'] as String?,
      concept: json['concept'] as String?,
      source: json['source'] as String? ?? 'manual',
      bankLegs: (json['bankLegs'] as List<dynamic>?)
              ?.map((e) => BankTransferLeg.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BankTransferLeg>[],
      awaitsBankCounterpart: json['awaitsBankCounterpart'] as bool? ?? false,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 2,
      migratedTransactionSnapshots:
          (json['migratedTransactionSnapshots'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              const <Map<String, dynamic>>[],
    );

Map<String, dynamic> _$$TransferImplToJson(_$TransferImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'sourceAssetId': instance.sourceAssetId,
      'sourceAssetName': instance.sourceAssetName,
      'destinationType':
          _$TransferDestinationTypeEnumMap[instance.destinationType]!,
      'destinationId': instance.destinationId,
      'destinationName': instance.destinationName,
      'note': instance.note,
      'concept': instance.concept,
      'source': instance.source,
      'bankLegs': instance.bankLegs.map((e) => e.toJson()).toList(),
      'awaitsBankCounterpart': instance.awaitsBankCounterpart,
      'schemaVersion': instance.schemaVersion,
      'migratedTransactionSnapshots': instance.migratedTransactionSnapshots,
    };

const _$TransferDestinationTypeEnumMap = {
  TransferDestinationType.asset: 'asset',
  TransferDestinationType.debt: 'debt',
};
