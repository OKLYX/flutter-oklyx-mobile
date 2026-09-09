import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/outbound_order.dart';
import '../../domain/entities/purchase_candidate.dart';
import '../../domain/entities/return_candidate.dart';
import '../../domain/entities/stock_balance.dart';
import '../../domain/entities/stock_movement.dart';

abstract class StockLedgerState {}

/// 진입 직후.
class StockLedgerInitial extends StockLedgerState {}

/// 최초 로드 중 (전체 화면 스피너).
class StockLedgerLoading extends StockLedgerState {}

/// 최초 로드 실패 (전체 화면 + 재시도).
class StockLedgerError extends StockLedgerState {
  final String message;

  StockLedgerError({required this.message});
}

/// 조회 성공 상태 — 세 화면이 이 상태 하나를 나눠 쓴다.
///
/// 진행 상태를 별도 상태로 두지 않고 플래그로 표현한다: 필터·입력값을 유지해야 하기 때문이다.
/// [actionInProgressKey] 는 **어느 줄이 처리 중인지**를 담아 per-action 스피너의 근거가 된다
/// (출고 확인은 줄마다 개별 요청이라 전체 스피너로는 어디가 도는지 알 수 없다).
///
/// [actionError]/[actionMessage] 는 1회성 안내다 — SnackBar 로 띄운 뒤
/// `ClearStockLedgerNotice` 로 지운다.
class StockLedgerLoaded extends StockLedgerState {
  /// 판매자 필터·귀속 드롭다운의 원본. 실패해도 비치명적(빈 목록).
  final List<Seller> sellers;

  /// 화면에 적용 중인 판매자 필터 (null = 전체).
  final int? sellerId;

  /// 재고 조회 검색어.
  final String keyword;

  final List<StockBalance> balances;
  final List<StockMovement> movements;
  final List<OutboundOrder> outbound;
  final List<OutboundUnexpanded> unexpanded;
  final List<PurchaseCandidate> purchaseCandidates;
  final List<ReturnCandidate> returnCandidates;

  final bool isRefreshing;
  final bool isLoadingMovements;
  final String? actionInProgressKey;
  final String? actionError;
  final String? actionMessage;

  StockLedgerLoaded({
    this.sellers = const [],
    this.sellerId,
    this.keyword = '',
    this.balances = const [],
    this.movements = const [],
    this.outbound = const [],
    this.unexpanded = const [],
    this.purchaseCandidates = const [],
    this.returnCandidates = const [],
    this.isRefreshing = false,
    this.isLoadingMovements = false,
    this.actionInProgressKey,
    this.actionError,
    this.actionMessage,
  });

  StockLedgerLoaded copyWith({
    List<Seller>? sellers,
    int? sellerId,
    bool clearSellerId = false,
    String? keyword,
    List<StockBalance>? balances,
    List<StockMovement>? movements,
    List<OutboundOrder>? outbound,
    List<OutboundUnexpanded>? unexpanded,
    List<PurchaseCandidate>? purchaseCandidates,
    List<ReturnCandidate>? returnCandidates,
    bool? isRefreshing,
    bool? isLoadingMovements,
    String? actionInProgressKey,
    bool clearActionInProgress = false,
    String? actionError,
    bool clearActionError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return StockLedgerLoaded(
      sellers: sellers ?? this.sellers,
      sellerId: clearSellerId ? null : (sellerId ?? this.sellerId),
      keyword: keyword ?? this.keyword,
      balances: balances ?? this.balances,
      movements: movements ?? this.movements,
      outbound: outbound ?? this.outbound,
      unexpanded: unexpanded ?? this.unexpanded,
      purchaseCandidates: purchaseCandidates ?? this.purchaseCandidates,
      returnCandidates: returnCandidates ?? this.returnCandidates,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMovements: isLoadingMovements ?? this.isLoadingMovements,
      actionInProgressKey: clearActionInProgress
          ? null
          : (actionInProgressKey ?? this.actionInProgressKey),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }
}
