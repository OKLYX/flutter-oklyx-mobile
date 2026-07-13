import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/platform_carrier_code.dart';

abstract class PlatformCodeState {}

class PlatformCodeInitial extends PlatformCodeState {}

class PlatformCodeLoading extends PlatformCodeState {}

class PlatformCodeLoaded extends PlatformCodeState {
  final List<PlatformCarrierCode> codes;
  PlatformCodeLoaded(this.codes);
}

/// 목록 조회 실패.
class PlatformCodeError extends PlatformCodeState {
  final String message;
  PlatformCodeError(this.message);
}

/// 생성/수정/삭제 진행 중.
class PlatformCodeActionInProgress extends PlatformCodeState {}

/// 생성/수정/삭제 성공 (transient — SnackBar + 다이얼로그 닫기 후 목록 재조회).
class PlatformCodeActionSuccess extends PlatformCodeState {
  final String message;
  PlatformCodeActionSuccess(this.message);
}

/// 생성/수정/삭제 실패 (transient — 다이얼로그 유지).
class PlatformCodeActionFailure extends PlatformCodeState {
  final String message;
  PlatformCodeActionFailure(this.message);
}
