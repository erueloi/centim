// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetImpl _$$AssetImplFromJson(Map<String, dynamic> json) => _$AssetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$AssetTypeEnumMap, json['type']),
      bankName: json['bankName'] as String?,
    );

Map<String, dynamic> _$$AssetImplToJson(_$AssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'type': _$AssetTypeEnumMap[instance.type]!,
      'bankName': instance.bankName,
    };

const _$AssetTypeEnumMap = {
  AssetType.realEstate: 'realEstate',
  AssetType.bankAccount: 'bankAccount',
  AssetType.cash: 'cash',
  AssetType.other: 'other',
};
