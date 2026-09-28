import 'package:equatable/equatable.dart';

/// 주문관리 설정 (GET/PUT /api/admin/order-settings, FEATURE_2609_75 / D4·D12).
///
/// 🔴 두 값 모두 **KST 벽시계 문자열**이다 — `DateTime.parse` 로 바꿔 시간대 계산을 하지 않는다.
class OrderSetting extends Equatable {
  /// 기본 예약 발송 시각 'HH:mm' (한국시간).
  final String reservedShipmentTime;

  /// 그 시각의 다음 도래 시각 'yyyy-MM-ddTHH:mm:ss' (한국시간) — [예약 발송] 기본값(D20).
  final String nextExecuteAt;

  const OrderSetting({
    required this.reservedShipmentTime,
    required this.nextExecuteAt,
  });

  factory OrderSetting.fromJson(Map<String, dynamic> json) => OrderSetting(
        reservedShipmentTime: json['reservedShipmentTime'] as String? ?? '',
        nextExecuteAt: json['nextExecuteAt'] as String? ?? '',
      );

  @override
  List<Object?> get props => [reservedShipmentTime, nextExecuteAt];
}
