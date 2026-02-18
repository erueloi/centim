import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

enum AssetType { realEstate, bankAccount, cash, other }

@freezed
class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String name,
    required double amount,
    required AssetType type,
    String? bankName,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}
