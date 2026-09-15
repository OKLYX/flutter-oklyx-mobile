import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/alert_summary.dart';

/// 알림 배지 카운트 계약 (FEATURE_2609_49 / D9).
///
/// 🔴 반환 타입은 `Either<Failure, _>` 다(`InquiryRepository` 와 같은 규약) — 이 feature 만
/// 예외를 던지는 식으로 만들면 호출부가 갈린다.
abstract class AlertRepository {
  /// 처리 대기 건수
  /// GET /api/alerts/summary
  ///
  /// ⚠️ 실패는 화면에 띄우지 않는다 — 호출자(Bloc)가 직전 값을 유지한다.
  Future<Either<Failure, AlertSummary>> getSummary();
}
