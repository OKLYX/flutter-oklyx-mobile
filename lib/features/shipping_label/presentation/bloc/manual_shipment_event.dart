import 'package:equatable/equatable.dart';

abstract class ManualShipmentEvent extends Equatable {
  const ManualShipmentEvent();

  @override
  List<Object?> get props => [];
}

/// 택배사 드롭다운 항목 조회 (섹션 생성 시 자동 발행 — 쿠팡 호출이 아니라 DB lookup 이라
/// 송장시트와 달리 버튼을 기다리지 않는다). 조회 실패 시 `다시 시도` 버튼이 재발행한다.
class LoadCarrierOptions extends ManualShipmentEvent {
  final String platform;

  const LoadCarrierOptions(this.platform);

  @override
  List<Object?> get props => [platform];
}

/// 드롭다운 선택.
class CarrierSelected extends ManualShipmentEvent {
  final int carrierId;

  const CarrierSelected(this.carrierId);

  @override
  List<Object?> get props => [carrierId];
}

/// 단건 발송처리(또는 송장수정) 전송 — 모드 판정은 서버가 한다(PLAN 2609_11 D3).
class SubmitManualShipment extends ManualShipmentEvent {
  /// order_item PK (쿠팡 orderId 아님). 전송 대상은 이 라인이 속한 박스 전체다(D1).
  final int orderItemId;
  final String invoiceNumber;

  const SubmitManualShipment({
    required this.orderItemId,
    required this.invoiceNumber,
  });

  @override
  List<Object?> get props => [orderItemId, invoiceNumber];
}

/// 송장번호를 고칠 때 직전 전송 실패 문구를 지운다(웹의 onChange 클리어와 같은 규칙).
/// 위젯이 `errorMessage != null` 일 때만 발행하므로 글자마다 emit 되지 않는다.
class SubmitErrorCleared extends ManualShipmentEvent {
  const SubmitErrorCleared();
}
