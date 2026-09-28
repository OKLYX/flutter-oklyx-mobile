import 'package:equatable/equatable.dart';

/// 예약 발송 현황 1행 = 주문(배송 묶음) 1개 (FEATURE_2609_75 / D30).
/// GET /api/admin/reserved-shipments · GET /api/admin/reserved-shipments/orders/{externalOrderId}.
///
/// [id] = 결과 행 id — 행 작업(시각 변경·다시 시도)의 경로 변수. [orderShipmentId] = [송장 수정] 경로 변수(D18).
/// [orderItemIds] = [예약 취소] 입력. [status] = 그 행이 속한 예약의 상태.
/// 🔴 시각 필드는 KST 벽시계 문자열이다 — 시간대 계산을 하지 않는다.
class ReservedShipmentRow extends Equatable {
  final int id;
  final int orderShipmentId;
  final String externalOrderId;
  final String externalShipmentId;
  final List<int> orderItemIds;
  final String executeAt;
  final String? lastRunAt;

  /// SCHEDULED · RUNNING · DONE · STOPPED · CANCELLED — 라벨은 [kReservedStatusLabels].
  final String status;

  /// ON_TIME · DELAYED · null(실행 전). DELAYED = 「지연 실행」(D15).
  final String? firstRunKind;
  final String carrierCode;
  final String? invoiceNumber;

  /// PENDING · SUCCEEDED · FAILED · CANCELLED · EXTERNAL · RELEASED — 라벨은 [kReservedResultLabels].
  final String result;
  final String? failureReason;

  const ReservedShipmentRow({
    required this.id,
    required this.orderShipmentId,
    required this.externalOrderId,
    required this.externalShipmentId,
    required this.orderItemIds,
    required this.executeAt,
    required this.lastRunAt,
    required this.status,
    required this.firstRunKind,
    required this.carrierCode,
    required this.invoiceNumber,
    required this.result,
    required this.failureReason,
  });

  factory ReservedShipmentRow.fromJson(Map<String, dynamic> json) =>
      ReservedShipmentRow(
        id: (json['id'] as num).toInt(),
        orderShipmentId: (json['orderShipmentId'] as num).toInt(),
        externalOrderId: json['externalOrderId'] as String? ?? '',
        externalShipmentId: json['externalShipmentId'] as String? ?? '',
        orderItemIds: (json['orderItemIds'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        executeAt: json['executeAt'] as String? ?? '',
        lastRunAt: json['lastRunAt'] as String?,
        status: json['status'] as String? ?? '',
        firstRunKind: json['firstRunKind'] as String?,
        carrierCode: json['carrierCode'] as String? ?? '',
        invoiceNumber: json['invoiceNumber'] as String?,
        result: json['result'] as String? ?? '',
        failureReason: json['failureReason'] as String?,
      );

  /// 대기·실패 = 끝나지 않은 행.
  bool get isOpen => result == 'PENDING' || result == 'FAILED';

  /// [시각 변경] 노출 = 예약됨 + 실행 시작 전 + 대기(D18 행3). 판정은 서버가 다시 한다.
  bool get isEditable =>
      status == 'SCHEDULED' && firstRunKind == null && result == 'PENDING';

  /// [송장 수정] 노출 = 끝나지 않은 행 + 실행 중(RUNNING) 아님(D18 🔁 — 실행 중만 막는다).
  bool get isInvoiceEditable => isOpen && status != 'RUNNING';

  @override
  List<Object?> get props => [
        id,
        orderShipmentId,
        externalOrderId,
        externalShipmentId,
        orderItemIds,
        executeAt,
        lastRunAt,
        status,
        firstRunKind,
        carrierCode,
        invoiceNumber,
        result,
        failureReason,
      ];
}

/// 예약 상태 라벨(PLAN §4-5) — 웹과 글자까지 같다.
const Map<String, String> kReservedStatusLabels = {
  'SCHEDULED': '예약됨',
  'RUNNING': '처리 중',
  'DONE': '완료',
  'STOPPED': '자동 재시도 중단',
  'CANCELLED': '취소됨',
};

/// 예약 결과 라벨(PLAN §4-5) — 웹과 글자까지 같다.
const Map<String, String> kReservedResultLabels = {
  'PENDING': '대기',
  'SUCCEEDED': '완료',
  'FAILED': '실패',
  'CANCELLED': '취소됨',
  'EXTERNAL': '외부에서 처리됨',
  'RELEASED': '예약 해제',
};
