import 'package:equatable/equatable.dart';

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
