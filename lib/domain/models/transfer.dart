import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.freezed.dart';
part 'transfer.g.dart';

enum TransferDestinationType { asset, debt }

/// Una pota bancària real consumida per un traspàs importat.
///
/// `bankAccountKey + bankTxId` és la identitat estable. Cal conservar
/// `bankAccountKey` perquè diversos comptes reals poden apuntar al mateix
/// `Asset` de Cèntim.
class BankTransferLeg {
  final String bankAccountKey;
  final String bankTxId;
  final double signedAmount;
  final DateTime date;
  final String centimAssetId;
  final String? concept;

  const BankTransferLeg({
    required this.bankAccountKey,
    required this.bankTxId,
    required this.signedAmount,
    required this.date,
    required this.centimAssetId,
    this.concept,
  });

  String get identity => '$bankAccountKey\u0000$bankTxId';

  factory BankTransferLeg.fromJson(Map<String, dynamic> json) {
    return BankTransferLeg(
      bankAccountKey: json['bankAccountKey'] as String? ?? '',
      bankTxId: json['bankTxId'] as String? ?? '',
      signedAmount: (json['signedAmount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] as String),
      centimAssetId: json['centimAssetId'] as String? ?? '',
      concept: json['concept'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'bankAccountKey': bankAccountKey,
        'bankTxId': bankTxId,
        'signedAmount': signedAmount,
        'date': date.toIso8601String(),
        'centimAssetId': centimAssetId,
        'concept': concept,
      };
}

@freezed
class Transfer with _$Transfer {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
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
    String? concept,
    @Default('manual') String source,
    @Default(<BankTransferLeg>[]) List<BankTransferLeg> bankLegs,
    @Default(false) bool awaitsBankCounterpart,
    @Default(2) int schemaVersion,
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> migratedTransactionSnapshots,
  }) = _Transfer;

  // Els 14 documents històrics no porten versió i es mantenen intactes.
  factory Transfer.fromJson(Map<String, dynamic> json) =>
      _$TransferFromJson(_withLegacyTransferSchemaVersion(json));
}

Map<String, dynamic> _withLegacyTransferSchemaVersion(
  Map<String, dynamic> json,
) =>
    {
      ...json,
      'schemaVersion': json['schemaVersion'] ?? 1,
    };
