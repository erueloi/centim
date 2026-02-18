import 'package:freezed_annotation/freezed_annotation.dart';

part 'household_group.freezed.dart';
part 'household_group.g.dart';

@freezed
class HouseholdGroup with _$HouseholdGroup {
  const factory HouseholdGroup({
    required String id,
    required String name,
    required List<String> memberIds,
    required String ownerId,
    required String inviteCode,
    @Default(0.0) double totalAssets,
  }) = _HouseholdGroup;

  factory HouseholdGroup.fromJson(Map<String, dynamic> json) =>
      _$HouseholdGroupFromJson(json);
}
