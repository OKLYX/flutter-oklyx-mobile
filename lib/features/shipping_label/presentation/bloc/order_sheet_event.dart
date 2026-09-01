import 'package:equatable/equatable.dart';

abstract class OrderSheetEvent extends Equatable {
  const OrderSheetEvent();

  @override
  List<Object?> get props => [];
}

/// 주문 단건 시트 조회 (버튼 탭 시에만 발행 — 페이지 진입 시 자동 조회하지 않는다).
class LoadOrderSheet extends OrderSheetEvent {
  /// order_item PK (쿠팡 orderId 아님).
  final int orderItemId;

  const LoadOrderSheet(this.orderItemId);

  @override
  List<Object?> get props => [orderItemId];
}

/// 특정 라인의 택배수량 편집 (최소 1 은 BLoC 에서 강제).
class UpdateOrderSheetParcelQuantity extends OrderSheetEvent {
  final String rowKey;
  final int parcelQuantity;

  const UpdateOrderSheetParcelQuantity(this.rowKey, this.parcelQuantity);

  @override
  List<Object?> get props => [rowKey, parcelQuantity];
}

/// 편집된 rows 로 xlsx export 요청.
class ExportOrderSheetRequested extends OrderSheetEvent {
  const ExportOrderSheetRequested();
}
