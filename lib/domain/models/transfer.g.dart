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
    };

const _$TransferDestinationTypeEnumMap = {
  TransferDestinationType.asset: 'asset',
  TransferDestinationType.debt: 'debt',
};
