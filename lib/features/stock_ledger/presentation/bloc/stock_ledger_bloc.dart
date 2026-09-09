import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/usecases/get_sellers_usecase.dart';
import '../../domain/entities/outbound_order.dart';
import '../../domain/entities/purchase_candidate.dart';
import '../../domain/entities/return_candidate.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/usecases/confirm_outbound_usecase.dart';
import '../../domain/usecases/get_balances_usecase.dart';
import '../../domain/usecases/get_movements_usecase.dart';
import '../../domain/usecases/get_outbound_usecase.dart';
import '../../domain/usecases/get_stock_candidates_usecase.dart';
import '../../domain/usecases/record_movement_usecase.dart';
import 'stock_ledger_event.dart';
import 'stock_ledger_state.dart';

/// 재고 원장 BLoC (PLAN 2609_28 D6~D14 · D21).
///
/// **용도**: 입고·조정 / 출고 확인 / 재고 조회 세 화면을 하나가 든다(구매목록 BLoC 과 같은 판단).
/// **파일**: lib/features/stock_ledger/presentation/bloc/stock_ledger_bloc.dart
///
/// ⚠️ 금액·부호를 여기서 계산하지 않는다 — 부호는 서버가 정한다(D6). 화면은 받은 값을 그대로 쓴다.
/// ⚠️ [ConfirmOutbound] 성공 시 **전체 재조회 금지** — 그 줄의 확인 수량만 갱신한다.
///    전체를 다시 부르면 스크롤이 튀어 작업 흐름이 끊긴다(D12).
/// 🔴 판매자 필터는 상태가 들고, 잔량은 (물품 × 판매자) 행이다(2609_29 D5).
class StockLedgerBloc extends Bloc<StockLedgerEvent, StockLedgerState> {
  final GetBalancesUseCase getBalancesUseCase;
  final GetMovementsUseCase getMovementsUseCase;
  final RecordMovementUseCase recordMovementUseCase;
  final GetStockCandidatesUseCase getStockCandidatesUseCase;
  final GetOutboundUseCase getOutboundUseCase;
  final ConfirmOutboundUseCase confirmOutboundUseCase;
  final GetSellersUseCase getSellersUseCase;

  StockLedgerBloc({
    required this.getBalancesUseCase,
    required this.getMovementsUseCase,
    required this.recordMovementUseCase,
    required this.getStockCandidatesUseCase,
    required this.getOutboundUseCase,
    required this.confirmOutboundUseCase,
    required this.getSellersUseCase,
  }) : super(StockLedgerInitial()) {
    on<LoadEntryData>(_onLoadEntryData);
    on<LoadBalances>(_onLoadBalances);
    on<LoadMovements>(_onLoadMovements);
    on<RecordMovement>(_onRecordMovement);
    on<LoadOutbound>(_onLoadOutbound);
    on<ConfirmOutbound>(_onConfirmOutbound);
    on<ClearStockLedgerNotice>(_onClearNotice);
  }

  /// 판매자 목록은 세 화면이 다 쓰고 거의 변하지 않는다 — 한 번만 받아 상태에 남긴다.
  /// 실패는 비치명적이다: 드롭다운이 빈 채로 뜨고 나머지 화면은 동작한다.
  Future<List<Seller>> _sellers(StockLedgerLoaded? current) async {
    if (current != null && current.sellers.isNotEmpty) return current.sellers;
    final result = await getSellersUseCase();
    return result.fold((_) => const <Seller>[], (list) => list);
  }

  StockLedgerLoaded? _loaded() {
    final current = state;
    return current is StockLedgerLoaded ? current : null;
  }

  /// 입고·조정 화면 진입 — 선택지(구매·반품)와 최근 이력을 함께 받는다.
  Future<void> _onLoadEntryData(
    LoadEntryData event,
    Emitter<StockLedgerState> emit,
  ) async {
    final current = _loaded();
    if (current == null) emit(StockLedgerLoading());

    final sellers = await _sellers(current);
    final movementsResult = await getMovementsUseCase();
    // 이력 조회 실패만 치명적이다 — 이 화면의 본문이 최근 이력이다.
    if (movementsResult.isLeft()) {
      emit(StockLedgerError(
        message: movementsResult.getLeft().toNullable()!.message,
      ));
      return;
    }
    final movements =
        movementsResult.getOrElse((_) => const <StockMovement>[]);

    final purchases = await getStockCandidatesUseCase.purchases();
    final returns = await getStockCandidatesUseCase.returns();

    emit((current ?? StockLedgerLoaded()).copyWith(
      sellers: sellers,
      movements: movements,
      purchaseCandidates:
          purchases.getOrElse((_) => const <PurchaseCandidate>[]),
      returnCandidates: returns.getOrElse((_) => const <ReturnCandidate>[]),
      isRefreshing: false,
      clearActionInProgress: true,
    ));
  }

  Future<void> _onLoadBalances(
    LoadBalances event,
    Emitter<StockLedgerState> emit,
  ) async {
    final current = _loaded();
    if (current == null) emit(StockLedgerLoading());

    final sellers = await _sellers(current);
    final keyword = event.keyword ?? current?.keyword ?? '';
    final result = await getBalancesUseCase(
      sellerId: event.sellerId,
      keyword: keyword,
    );
    result.fold(
      (failure) {
        if (current == null) {
          emit(StockLedgerError(message: failure.message));
        } else {
          emit(current.copyWith(
            isRefreshing: false,
            actionError: failure.message,
          ));
        }
      },
      (balances) => emit((current ?? StockLedgerLoaded()).copyWith(
        sellers: sellers,
        sellerId: event.sellerId,
        clearSellerId: event.sellerId == null,
        keyword: keyword,
        balances: balances,
        isRefreshing: false,
      )),
    );
  }

  Future<void> _onLoadMovements(
    LoadMovements event,
    Emitter<StockLedgerState> emit,
  ) async {
    final current = _loaded();
    if (current == null) emit(StockLedgerLoading());

    emit((current ?? StockLedgerLoaded()).copyWith(isLoadingMovements: true));

    final result = await getMovementsUseCase(
      productId: event.productId,
      sellerId: event.sellerId,
      from: event.from,
      to: event.to,
    );
    final latest = _loaded() ?? StockLedgerLoaded();
    result.fold(
      (failure) => emit(latest.copyWith(
        isLoadingMovements: false,
        actionError: failure.message,
      )),
      (movements) => emit(latest.copyWith(
        isLoadingMovements: false,
        movements: movements,
      )),
    );
  }

  /// 기록 성공 → 최근 이력과 선택지를 다시 받는다.
  /// (입고 화면은 목록 스크롤이 얕아 재조회로 흐름이 끊기지 않는다 — 출고와 다르다.)
  Future<void> _onRecordMovement(
    RecordMovement event,
    Emitter<StockLedgerState> emit,
  ) async {
    final current = _loaded();
    if (current == null) return;
    if (current.actionInProgressKey != null) return;

    emit(current.copyWith(
      actionInProgressKey: 'record',
      clearActionError: true,
      clearActionMessage: true,
    ));

    final result = await recordMovementUseCase(
      productId: event.productId,
      sellerId: event.sellerId,
      movementType: event.movementType,
      quantity: event.quantity,
      reason: event.reason,
      reasonNote: event.reasonNote,
      unitPrice: event.unitPrice,
      orderClaimId: event.orderClaimId,
      purchaseRecordId: event.purchaseRecordId,
      movedOn: event.movedOn,
    );

    await result.fold(
      (failure) async => emit(current.copyWith(
        clearActionInProgress: true,
        // 서버 400 원문을 그대로 보여준다 — 조합 규칙의 정본은 서버다.
        actionError: failure.message,
      )),
      (movement) async {
        final movements = await getMovementsUseCase();
        final purchases = await getStockCandidatesUseCase.purchases();
        final returns = await getStockCandidatesUseCase.returns();
        emit(current.copyWith(
          clearActionInProgress: true,
          movements: movements.getOrElse((_) => [movement, ...current.movements]),
          purchaseCandidates:
              purchases.getOrElse((_) => current.purchaseCandidates),
          returnCandidates: returns.getOrElse((_) => current.returnCandidates),
          actionMessage: '${event.movementType.label} 기록했습니다',
        ));
      },
    );
  }

  Future<void> _onLoadOutbound(
    LoadOutbound event,
    Emitter<StockLedgerState> emit,
  ) async {
    final current = _loaded();
    if (current == null) emit(StockLedgerLoading());

    final sellers = await _sellers(current);
    final result = await getOutboundUseCase(sellerId: event.sellerId);
    result.fold(
      (failure) {
        if (current == null) {
          emit(StockLedgerError(message: failure.message));
        } else {
          emit(current.copyWith(
            isRefreshing: false,
            actionError: failure.message,
          ));
        }
      },
      (outbound) => emit((current ?? StockLedgerLoaded()).copyWith(
        sellers: sellers,
        sellerId: event.sellerId,
        clearSellerId: event.sellerId == null,
        outbound: outbound.orders,
        unexpanded: outbound.unexpanded,
        isRefreshing: false,
        clearActionInProgress: true,
      )),
    );
  }

  /// 출고 확인 1건 — 성공하면 **그 줄만** 갱신한다(재조회 금지, D12).
  /// 전량 확인된 카드는 목록에서 뺀다.
  Future<void> _onConfirmOutbound(
    ConfirmOutbound event,
    Emitter<StockLedgerState> emit,
  ) async {
    final current = _loaded();
    if (current == null) return;
    final key = outboundActionKey(event.orderLineId, event.productId);
    if (current.actionInProgressKey != null) return;

    emit(current.copyWith(
      actionInProgressKey: key,
      clearActionError: true,
      clearActionMessage: true,
    ));

    final result = await confirmOutboundUseCase(
      orderLineId: event.orderLineId,
      productId: event.productId,
      quantity: event.quantity,
      movedOn: event.movedOn,
    );

    result.fold(
      (failure) => emit(current.copyWith(
        clearActionInProgress: true,
        actionError: failure.message,
      )),
      (_) {
        final updated = <OutboundOrder>[];
        for (final order in current.outbound) {
          if (order.orderLineId != event.orderLineId) {
            updated.add(order);
            continue;
          }
          final products = order.products
              .map((p) => p.productId == event.productId
                  ? p.copyWith(confirmedQty: p.confirmedQty + event.quantity)
                  : p)
              .toList();
          final next = order.copyWith(products: products);
          // 남은 수량이 0 이 된 카드는 화면에서 빠진다.
          if (!next.fullyConfirmed) updated.add(next);
        }
        emit(current.copyWith(
          clearActionInProgress: true,
          outbound: updated,
          actionMessage: '출고 ${event.quantity}건 확인했습니다',
        ));
      },
    );
  }

  void _onClearNotice(
    ClearStockLedgerNotice event,
    Emitter<StockLedgerState> emit,
  ) {
    final current = _loaded();
    if (current == null) return;
    if (current.actionError == null && current.actionMessage == null) return;
    emit(current.copyWith(clearActionError: true, clearActionMessage: true));
  }

  /// 출고 확인 줄의 진행 키 — 화면이 스피너를 어느 줄에 띄울지 이 값으로 판단한다.
  static String outboundActionKey(int orderLineId, int productId) =>
      'outbound:$orderLineId:$productId';
}
