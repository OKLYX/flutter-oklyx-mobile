import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/alert_feed_item.dart';
import '../entities/alert_summary.dart';
import '../repositories/alert_repository.dart';

/// 알림 UseCase (`InquiryUseCase` 와 동일하게 Repository 에 위임).
class AlertUseCase {
  final AlertRepository repository;

  AlertUseCase({required this.repository});

  /// 처리 대기 건수(결제완료 상품·미완결 클레임·미답변 문의).
  Future<Either<Failure, AlertSummary>> getSummary() => repository.getSummary();

  /// 처리해야 할 일 목록 한 장. [cursor] 가 null 이면 첫 장이다.
  Future<Either<Failure, AlertFeedPage>> getFeed({
    AlertType? type,
    String? cursor,
    int size = 50,
  }) =>
      repository.getFeed(type: type, cursor: cursor, size: size);
}
