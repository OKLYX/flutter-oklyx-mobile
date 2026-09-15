import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/alert_summary.dart';
import '../repositories/alert_repository.dart';

/// 알림 배지 UseCase (`InquiryUseCase` 와 동일하게 Repository 에 위임).
class AlertUseCase {
  final AlertRepository repository;

  AlertUseCase({required this.repository});

  /// 처리 대기 건수(미완결 클레임·미답변 문의).
  Future<Either<Failure, AlertSummary>> getSummary() => repository.getSummary();
}
