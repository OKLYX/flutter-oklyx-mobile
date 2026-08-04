import 'package:equatable/equatable.dart';

/// 송장 접수시트 편집용 미리보기 행 (V2 preview, 백엔드 ShippingLabelPreviewRow 대응).
///
/// preview 로 받은 full row 를 BLoC 이 보관하고, 화면엔 축약(이름+배송지 앞부분)만
/// 표시한다. 사용자가 [parcelQuantity](택배수량)를 조정한 뒤 export 레그로 되돌려 xlsx 를 만든다.
///
/// ⚠️ [rowKey] 는 서버(01_BACKEND)가 발급한 라인 고유키(`shipmentBoxId:vendorItemId`)로,
/// [fromJson] 으로만 채운다(클라 재생성 금지). 편집/리스트 key 로만 사용한다.
class ShippingLabelPreviewRow extends Equatable {
  final String rowKey;
  final String receiverName;
  final String receiverPhone;
  final String postCode;
  final String address;
  final String productName;
  final String vendorItemId;
  final String orderId;
  final String deliveryMessage;
  final String shipmentBoxId;
  final String sellerName;
  final String platform;

  /// 내품수량(주문 개수).
  final int quantity;

  /// 택배수량(박스 수), 기본 1. 사용자가 편집하는 유일한 필드.
  final int parcelQuantity;

  const ShippingLabelPreviewRow({
    required this.rowKey,
    required this.receiverName,
    required this.receiverPhone,
    required this.postCode,
    required this.address,
    required this.productName,
    required this.vendorItemId,
    required this.orderId,
    required this.deliveryMessage,
    required this.shipmentBoxId,
    required this.sellerName,
    required this.platform,
    required this.quantity,
    this.parcelQuantity = 1,
  });

  factory ShippingLabelPreviewRow.fromJson(Map<String, dynamic> j) =>
      ShippingLabelPreviewRow(
        rowKey: j['rowKey']?.toString() ?? '',
        receiverName: j['receiverName']?.toString() ?? '',
        receiverPhone: j['receiverPhone']?.toString() ?? '',
        postCode: j['postCode']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        productName: j['productName']?.toString() ?? '',
        vendorItemId: j['vendorItemId']?.toString() ?? '',
        orderId: j['orderId']?.toString() ?? '',
        deliveryMessage: j['deliveryMessage']?.toString() ?? '',
        shipmentBoxId: j['shipmentBoxId']?.toString() ?? '',
        sellerName: j['sellerName']?.toString() ?? '',
        platform: j['platform']?.toString() ?? '',
        quantity: j['quantity'] as int? ?? 0,
        parcelQuantity: j['parcelQuantity'] as int? ?? 1,
      );

  /// export POST 용 — 백엔드 [ShippingLabelExportRequest.ExportRow] 필드와 정확히 일치.
  /// ⚠️ rowKey/vendorItemId 는 ExportRow 에 없어 xlsx 재매칭에 불필요하므로 제외한다.
  Map<String, dynamic> toJson() => {
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'postCode': postCode,
        'address': address,
        'productName': productName,
        'quantity': quantity,
        'parcelQuantity': parcelQuantity,
        'orderId': orderId,
        'deliveryMessage': deliveryMessage,
        'shipmentBoxId': shipmentBoxId,
        'sellerName': sellerName,
        'platform': platform,
      };

  /// 편집용 — 택배수량만 갱신한 새 인스턴스.
  ShippingLabelPreviewRow copyWith({int? parcelQuantity}) =>
      ShippingLabelPreviewRow(
        rowKey: rowKey,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        postCode: postCode,
        address: address,
        productName: productName,
        vendorItemId: vendorItemId,
        orderId: orderId,
        deliveryMessage: deliveryMessage,
        shipmentBoxId: shipmentBoxId,
        sellerName: sellerName,
        platform: platform,
        quantity: quantity,
        parcelQuantity: parcelQuantity ?? this.parcelQuantity,
      );

  @override
  List<Object?> get props => [
        rowKey,
        receiverName,
        receiverPhone,
        postCode,
        address,
        productName,
        vendorItemId,
        orderId,
        deliveryMessage,
        shipmentBoxId,
        sellerName,
        platform,
        quantity,
        parcelQuantity,
      ];
}
