import 'package:equatable/equatable.dart';

import 'shipment_confirm_state.dart';

abstract class ShipmentConfirmEvent extends Equatable {
  const ShipmentConfirmEvent();

  @override
  List<Object?> get props => [];
}

/// file_picker 실행 → xlsx 선택.
class PickFile extends ShipmentConfirmEvent {
  const PickFile();
}

/// 선택된 파일 업로드(발송처리).
class UploadShipment extends ShipmentConfirmEvent {
  const UploadShipment();
}

/// [다른 파일 업로드] / 다이얼로그 재초기화 (파일/결과/에러 비움).
class ResetShipmentConfirm extends ShipmentConfirmEvent {
  const ResetShipmentConfirm();
}

/// 결과 요약 칩 토글. [bucket] 이 현재 선택과 같으면 해제된다(PLAN 2609_12 D4).
class SelectResultBucket extends ShipmentConfirmEvent {
  final ResultBucket bucket;
  const SelectResultBucket(this.bucket);

  @override
  List<Object?> get props => [bucket];
}

/// 기본 예약 시각 = 주문관리 설정의 다음 도래 시각(FEATURE_2609_75 / D12). 다이얼로그를 열 때 1회.
class LoadDefaultExecuteAt extends ShipmentConfirmEvent {
  const LoadDefaultExecuteAt();
}

/// 예약 시각 변경 — [executeAt] = KST 'yyyy-MM-ddTHH:mm:ss'.
class ChangeExecuteAt extends ShipmentConfirmEvent {
  final String executeAt;
  const ChangeExecuteAt(this.executeAt);

  @override
  List<Object?> get props => [executeAt];
}

/// [예약 발송] — 선택된 파일의 송장만 저장한다(D20·D27).
class ReserveShipment extends ShipmentConfirmEvent {
  const ReserveShipment();
}
