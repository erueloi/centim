// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HouseholdGroupImpl _$$HouseholdGroupImplFromJson(Map<String, dynamic> json) =>
    _$HouseholdGroupImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      memberIds: (json['memberIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      ownerId: json['ownerId'] as String,
      inviteCode: json['inviteCode'] as String,
      totalAssets: (json['totalAssets'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$HouseholdGroupImplToJson(
  _$HouseholdGroupImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'memberIds': instance.memberIds,
  'ownerId': instance.ownerId,
  'inviteCode': instance.inviteCode,
  'totalAssets': instance.totalAssets,
};
