import '../../domain/entities/alert_summary.dart';

/// `GET /api/alerts/summary` 응답 → [AlertSummary].
///
/// ⚠️ 서버는 `long` 을 내려준다 — `num` 으로 읽고 `toInt()` 한다(`as int` 는 파싱 실패다).
class AlertSummaryModel extends AlertSummary {
  const AlertSummaryModel({
    required super.openClaims,
    required super.unansweredInquiries,
  });

  factory AlertSummaryModel.fromJson(Map<String, dynamic> json) =>
      AlertSummaryModel(
        openClaims: (json['openClaims'] as num?)?.toInt() ?? 0,
        unansweredInquiries:
            (json['unansweredInquiries'] as num?)?.toInt() ?? 0,
      );
}
