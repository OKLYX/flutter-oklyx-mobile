import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/marketplace_account/domain/entities/marketplace_account.dart';

abstract class MarketplaceAccountState extends Equatable {
  const MarketplaceAccountState();

  @override
  List<Object?> get props => [];
}

class MarketplaceAccountInitial extends MarketplaceAccountState {
  const MarketplaceAccountInitial();
}

class MarketplaceAccountLoading extends MarketplaceAccountState {
  const MarketplaceAccountLoading();
}

class MarketplaceAccountLoaded extends MarketplaceAccountState {
  final List<MarketplaceAccount> channels;

  const MarketplaceAccountLoaded(this.channels);

  @override
  List<Object?> get props => [channels];
}

/// 목록 조회 실패 상태.
class MarketplaceAccountError extends MarketplaceAccountState {
  final String message;

  const MarketplaceAccountError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 생성/수정/삭제 진행 중 (다이얼로그에서 스피너 표시).
class MarketplaceAccountActionInProgress extends MarketplaceAccountState {
  const MarketplaceAccountActionInProgress();
}

/// 생성/수정/삭제 성공 (transient — 스낵바 + 다이얼로그 닫기 트리거 후 목록 재조회).
class MarketplaceAccountActionSuccess extends MarketplaceAccountState {
  final String message;

  const MarketplaceAccountActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// 생성/수정/삭제 실패 (transient — 다이얼로그 유지, 오류 메시지 표시).
class MarketplaceAccountActionFailure extends MarketplaceAccountState {
  final String message;

  const MarketplaceAccountActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
