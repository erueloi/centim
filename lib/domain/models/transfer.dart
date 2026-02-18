import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.freezed.dart';
part 'transfer.g.dart';

enum TransferDestinationType { asset, debt }

@freezed
class Transfer with _$Transfer {
  const factory Transfer({
    required String id,
    required String groupId,
    required DateTime date,
    required double amount,
    required String sourceAssetId,
    required String sourceAssetName, // Snapshot
    required TransferDestinationType destinationType,
    required String destinationId,
    required String destinationName, // Snapshot
    String? note,
  }) = _Transfer;

  factory Transfer.fromJson(Map<String, dynamic> json) =>
      _$TransferFromJson(json);
}
