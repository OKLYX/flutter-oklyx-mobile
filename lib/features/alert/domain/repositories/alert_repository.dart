import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/alert_feed_item.dart';
import '../entities/alert_summary.dart';

/// 알림 계약 — 배지 카운트(FEATURE_2609_49 / D9) + 목록(FEATURE_2609_51).
///
/// 🔴 반환 타입은 `Either<Failure, _>` 다(`InquiryRepository` 와 같은 규약) — 이 feature 만
/// 예외를 던지는 식으로 만들면 호출부가 갈린다.
abstract class AlertRepository {
  /// 처리 대기 건수
  /// GET /api/alerts/summary
  ///
  /// ⚠️ 실패는 화면에 띄우지 않는다 — 호출자(Bloc)가 직전 값을 유지한다.
  Future<Either<Failure, AlertSummary>> getSummary();

  /// 처리해야 할 일 목록 한 장
  /// GET /api/alerts
  ///
  /// ⚠️ 목록 실패는 **화면에 띄운다**(카운트와 반대) — 빈 목록과 실패는 다른 이야기다.
  Future<Either<Failure, AlertFeedPage>> getFeed({
    AlertType? type,
    String? cursor,
    int size,
  });
}
