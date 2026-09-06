import 'package:equatable/equatable.dart';

/// 취소 사유 선택지 1개 (GET /api/admin/orders/cancel-reasons 응답 1행).
///
/// **용도**: 주문 상세 취소 섹션의 사유 드롭다운 항목.
///
/// ⚠️ 코드 → 라벨 상수를 모바일에 만들지 말 것 — 목록의 소유자는 서버다(PLAN 2609_25 D4).
/// 서버 enum(`OrderCancelReason`)이 라벨과 쿠팡 `middleCancelCode` 매핑을 함께 쥐고 있고
/// 요청 검증도 같은 목록을 쓴다. 여기에 사본을 두면 네이버가 다른 코드 집합을 쓰는 순간
/// 화면 2벌을 함께 고쳐야 한다.
class CancelReasonOption extends Equatable {
  /// 전송할 값 (예: `OUT_OF_STOCK`).
  final String code;

  /// 사용자에게 보일 한글 문구 (예: `상품 품절 / 재고 부족`).
  final String label;

  const CancelReasonOption({required this.code, required this.label});

  factory CancelReasonOption.fromJson(Map<String, dynamic> json) =>
      CancelReasonOption(
        code: json['code']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [code, label];
}
