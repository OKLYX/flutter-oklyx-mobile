import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_item.dart';

/// 내부 단계 배송 묶음 1개의 현재 송장 (FEATURE_2609_75 / D18).
/// GET /api/admin/reserved-shipments/orders/{externalOrderId}/invoices ·
/// PUT /api/admin/reserved-shipments/shipments/{orderShipmentId}/invoice.
///
/// [carrierCode]·[invoiceNumber] = 송장이 없으면 null. [internalStage] 는 [internalStageFrom] 으로 읽는다.
class StoredInvoice extends Equatable {
  final int orderShipmentId;
  final String externalShipmentId;
  final InternalStage? internalStage;
  final String? carrierCode;
  final String? invoiceNumber;

  const StoredInvoice({
    required this.orderShipmentId,
    required this.externalShipmentId,
    required this.internalStage,
    required this.carrierCode,
    required this.invoiceNumber,
  });

  factory StoredInvoice.fromJson(Map<String, dynamic> json) => StoredInvoice(
        orderShipmentId: (json['orderShipmentId'] as num).toInt(),
        externalShipmentId: json['externalShipmentId'] as String? ?? '',
        internalStage: internalStageFrom(json['internalStage'] as String?),
        carrierCode: json['carrierCode'] as String?,
        invoiceNumber: json['invoiceNumber'] as String?,
      );

  @override
  List<Object?> get props =>
      [orderShipmentId, externalShipmentId, internalStage, carrierCode, invoiceNumber];
}
