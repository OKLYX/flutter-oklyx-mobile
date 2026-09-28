import 'package:equatable/equatable.dart';

abstract class OrderSettingEvent extends Equatable {
  const OrderSettingEvent();

  @override
  List<Object?> get props => [];
}

/// 설정 조회 — 화면 진입 시 1회.
class OrderSettingRequested extends OrderSettingEvent {
  const OrderSettingRequested();
}

/// 기본 예약 발송 시각 저장. [reservedShipmentTime] = 'HH:mm'(한국시간).
class OrderSettingSaved extends OrderSettingEvent {
  final String reservedShipmentTime;

  const OrderSettingSaved(this.reservedShipmentTime);

  @override
  List<Object?> get props => [reservedShipmentTime];
}
