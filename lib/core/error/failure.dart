import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class DuplicateEmailFailure extends Failure {
  const DuplicateEmailFailure(super.message);
}

/// 클레임 처리 액션 전용 실패 (FEATURE_2609_21).
///
/// 기존 [ServerFailure] 로는 부족하다 — 화면이 **409(이미 처리됨)** 를 400 과 구분해야 하고,
/// 502 에서는 **쿠팡 원문**([resultCode]·[resultMessage], D15)을 그대로 보여줘야 한다.
/// 원문을 우리 문구로 덮으면 실계정 디버깅에서 검색이 안 된다.
class ClaimActionFailure extends Failure {
  /// HTTP 상태 코드. 400/409/502/403 분기가 전부 이 값 하나로 갈린다.
  final int? statusCode;

  /// 502 응답 `data.resultCode` — 마켓이 준 원문 코드.
  final String? resultCode;

  /// 502 응답 `data.resultMessage` — 마켓이 준 원문 메시지. 번역·요약 금지.
  final String? resultMessage;

  const ClaimActionFailure(
    super.message, {
    this.statusCode,
    this.resultCode,
    this.resultMessage,
  });

  @override
  List<Object?> get props => [message, statusCode, resultCode, resultMessage];
}
