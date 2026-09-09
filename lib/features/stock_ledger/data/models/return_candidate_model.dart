import '../../domain/entities/return_candidate.dart';

class ReturnCandidateModel extends ReturnCandidate {
  const ReturnCandidateModel({
    required super.orderClaimId,
    super.orderLineId,
    required super.itemName,
    super.externalOrderId,
    required super.claimQty,
    required super.receivedQty,
    required super.remainingQty,
    super.claimStatus,
    super.collectStatus,
    super.receivedAt,
  });

  factory ReturnCandidateModel.fromJson(Map<String, dynamic> json) {
    return ReturnCandidateModel(
      orderClaimId: json['orderClaimId'] as int,
      orderLineId: json['orderLineId'] as int?,
      itemName: json['itemName'] as String? ?? '',
      externalOrderId: json['externalOrderId'] as String?,
      claimQty: json['claimQty'] as int? ?? 0,
      receivedQty: json['receivedQty'] as int? ?? 0,
      remainingQty: json['remainingQty'] as int? ?? 0,
      claimStatus: json['claimStatus'] as String?,
      collectStatus: json['collectStatus'] as String?,
      receivedAt: json['receivedAt'] as String?,
    );
  }
}
