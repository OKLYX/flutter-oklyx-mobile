import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../../data/models/cancel_reason_option.dart';
import '../../data/models/elevenst_cancel_request.dart';
import '../../data/models/elevenst_choices.dart';
import '../../data/models/elevenst_delivery_line.dart';
import '../../data/models/internal_stage_result.dart';
import '../../data/models/order_acknowledge_result.dart';
import '../../data/models/order_cancel_result.dart';
import '../../data/models/order_refresh_result.dart';
import '../../data/models/order_setting.dart';
import '../entities/order_item.dart';
import '../entities/order_period.dart';
import '../entities/order_sync_result.dart';
import '../entities/sync_target.dart';
import '../repositories/order_repository.dart';

/// 주문 조회/동기화 UseCase (프론트 OrderUseCase와 동일하게 Repository에 위임)
class OrderUseCase {
  final OrderRepository repository;

  OrderUseCase({required this.repository});

  /// [from]/[to] 는 'YYYY-MM-DD'. 미지정 시 서버 기본 창(최근 2주).
  Future<Either<Failure, List<OrderItem>>> getOrders({
    int? sellerId,
    String? from,
    String? to,
  }) {
    return repository.getOrders(sellerId: sellerId, from: from, to: to);
  }

  /// [accountId] 를 주면 그 계정 1건만 동기화한다(진행 다이얼로그의 계정 단위 루프).
  /// ⚠️ 조회 범위는 서버가 정한다(기본 preset = QUICK).
  Future<Either<Failure, OrderSyncResult>> syncOrders({
    int? sellerId,
    int? accountId,
  }) {
    return repository.syncOrders(sellerId: sellerId, accountId: accountId);
  }

  /// 계정 1건의 지정 기간을 쿠팡에서 백필한다(빈 달 불러오기).
  Future<Either<Failure, OrderSyncResult>> syncPeriod({
    required int accountId,
    required String from,
    required String to,
  }) {
    return repository.syncPeriod(accountId: accountId, from: from, to: to);
  }

  Future<Either<Failure, List<SyncTarget>>> getSyncTargets({int? sellerId}) {
    return repository.getSyncTargets(sellerId: sellerId);
  }

  Future<Either<Failure, List<OrderMonth>>> getOrderMonths() {
    return repository.getOrderMonths();
  }

  /// 발주처리 — 일괄(출고관리)과 개별(주문 상세)이 같은 엔드포인트를 쓴다(D6).
  Future<Either<Failure, OrderAcknowledgeResult>> acknowledgeOrders(
    List<int> orderItemIds,
  ) {
    return repository.acknowledgeOrders(orderItemIds);
  }

  /// 주문 상태 갱신 — 개별(주문 상세, 길이 1)과 선택(출고관리)이 같은 엔드포인트를 쓴다(D6).
  Future<Either<Failure, OrderRefreshResult>> refreshOrders(
    List<int> orderItemIds,
  ) {
    return repository.refreshOrders(orderItemIds);
  }

  /// 취소 사유 목록 — 라벨의 소유자는 서버다(PLAN 2609_25 D4).
  Future<Either<Failure, List<CancelReasonOption>>> getCancelReasons() {
    return repository.getCancelReasons();
  }

  /// 발송 전 주문 취소 — 라인×수량 배열로 보낸다(주문 상세는 길이 1, D1·D6).
  Future<Either<Failure, OrderCancelResult>> cancelOrders(
    List<Map<String, dynamic>> lines,
    String reason,
  ) {
    return repository.cancelOrders(lines, reason);
  }

  /// 내부 발주처리 — 쿠팡 호출 없음(FEATURE_2609_75 / D1).
  Future<Either<Failure, InternalStageResult>> markInternal(
    List<int> orderItemIds,
  ) {
    return repository.markInternal(orderItemIds);
  }

  /// 내부 발주 해제(D18 행1).
  Future<Either<Failure, InternalStageResult>> releaseInternal(
    List<int> orderItemIds,
  ) {
    return repository.releaseInternal(orderItemIds);
  }

  /// 주문관리 설정 조회(D12).
  Future<Either<Failure, OrderSetting>> getOrderSetting() {
    return repository.getOrderSetting();
  }

  /// 주문관리 설정 저장 — 'HH:mm'(한국시간).
  Future<Either<Failure, OrderSetting>> updateOrderSetting(
    String reservedShipmentTime,
  ) {
    return repository.updateOrderSetting(reservedShipmentTime);
  }

  /// [예약 취소] — 발송대기중 → 내부 상품준비중(FEATURE_2609_75 / D18 행2).
  Future<Either<Failure, InternalStageResult>> cancelReservedItems(
    List<int> orderItemIds,
  ) {
    return repository.cancelReservedItems(orderItemIds);
  }

  /// 11st cancel requests of one order line (FEATURE_2610_17 / D19).
  Future<Either<Failure, List<ElevenstCancelRequest>>>
      getElevenstCancelRequests(int orderItemId) {
    return repository.getElevenstCancelRequests(orderItemId);
  }

  /// [취소 승인] — cannot be undone (D37).
  Future<Either<Failure, Unit>> approveElevenstCancel(int requestId) {
    return repository.approveElevenstCancel(requestId);
  }

  /// [취소 거부] — carrier · invoice · date sent 'yyyy-MM-dd' (D38).
  Future<Either<Failure, Unit>> rejectElevenstCancel(
    int requestId, {
    required String deliveryCompanyCode,
    required String invoiceNumber,
    required String sendDate,
  }) {
    return repository.rejectElevenstCancel(
      requestId,
      deliveryCompanyCode: deliveryCompanyCode,
      invoiceNumber: invoiceNumber,
      sendDate: sendDate,
    );
  }

  /// The 13 seller-return reasons (D39 ⑤).
  Future<Either<Failure, List<CancelReasonOption>>> getElevenstReturnReasons() {
    return repository.getElevenstReturnReasons();
  }

  /// [판매자가 대신 반품 신청] (D35 · D36 · D39 ⑤).
  Future<Either<Failure, Unit>> requestElevenstReturn(
    int orderItemId,
    Map<String, dynamic> body,
  ) {
    return repository.requestElevenstReturn(orderItemId, body);
  }

  /// The reason lists of [주문 취소] · [책임사유 오류로 거부] · [발송지연 안내]
  /// (FEATURE_2610_17 / D61 · D62 · D63).
  Future<Either<Failure, ElevenstChoices>> getElevenstChoices() =>
      repository.getElevenstChoices();

  /// 11st sale refusal of the whole line (D61) — cannot be undone.
  Future<Either<Failure, OrderCancelResult>> cancelElevenstLine(int orderItemId,
          int quantity, String reasonCode, String reasonText) =>
      repository.cancelElevenstLine(
          orderItemId, quantity, reasonCode, reasonText);

  /// [책임사유 오류로 거부] (D62) — cannot be undone.
  Future<Either<Failure, Unit>> rejectElevenstCancelFault(
          int requestId, Map<String, dynamic> body) =>
      repository.rejectElevenstCancelFault(requestId, body);

  /// Lines of the same 11st delivery (D64).
  Future<Either<Failure, List<ElevenstDeliveryLine>>> getElevenstDeliveryLines(
          int orderItemId) =>
      repository.getElevenstDeliveryLines(orderItemId);

  /// [발송지연 안내] (D63).
  Future<Either<Failure, Unit>> sendElevenstDeliveryDelay(
          int orderItemId, Map<String, dynamic> body) =>
      repository.sendElevenstDeliveryDelay(orderItemId, body);

  /// [방문수령 완료] (D66) — cannot be undone.
  Future<Either<Failure, Unit>> completeElevenstVisitPickup(
          int orderItemId, String certCode) =>
      repository.completeElevenstVisitPickup(orderItemId, certCode);

  /// [입고완료 처리] (D67) — cannot be undone.
  Future<Either<Failure, Unit>> confirmElevenstStock(int orderItemId) =>
      repository.confirmElevenstStock(orderItemId);
}
