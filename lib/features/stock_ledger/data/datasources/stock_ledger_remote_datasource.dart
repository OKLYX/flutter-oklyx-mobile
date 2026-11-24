import '../models/outbound_order_model.dart';
import '../models/purchase_candidate_model.dart';
import '../models/return_candidate_model.dart';
import '../models/stock_balance_model.dart';
import '../models/stock_movement_model.dart';
import '../models/confirm_outbound_params.dart';
import '../models/record_movement_params.dart';
import '../../domain/entities/stock_intake.dart';
import '../../domain/entities/stock_work.dart';
import '../models/intake_barcode_result_model.dart';
import '../models/claim_work_model.dart';

/// 실물 재고 원장 API (`/api/admin/stock/**`, PLAN 2609_28 D19 — ADMIN 전용).
///
/// 옛 재고 스택은 PLAN 2609_28 D21 로 제거됐다 — 호출 경로는 이 하나뿐이다.
abstract class StockLedgerRemoteDataSource {
  Future<List<StockBalanceModel>> balances(int? productId, int? sellerId, String? keyword);

  Future<List<StockMovementModel>> movements(
    int? productId,
    int? sellerId,
    String? from,
    String? to,
  );

  Future<StockMovementModel> record(RecordMovementParams params);

  Future<List<PurchaseCandidateModel>> purchaseCandidates(int? productId);

  Future<List<ReturnCandidateModel>> returnCandidates();

  Future<OutboundResultModel> outbound(int? sellerId, String? status);

  Future<List<StockMovementModel>> confirmOutbound(ConfirmOutboundParams params);

  /// `GET /api/admin/stock/intake/barcode` (FEATURE_2611_33 D5).
  Future<IntakeBarcodeResultModel> intakeBarcode(String value);

  /// `POST /api/admin/stock/intake` — returns the lot ids (D4 ⑧ · ⑨).
  Future<List<int>> intake(String movedOn, List<StockIntakeLine> lines);

  /// `POST /api/admin/stock/outbound-work` (FEATURE_2611_34 D35 ⑤).
  Future<void> outboundWork(
    String movedOn,
    List<OutboundWorkLineRequest> lines,
  );

  /// `GET …/return-work/by-return-invoice` (FEATURE_2611_34 D35 ①).
  Future<List<ClaimWorkModel>> claimsByReturnInvoice(String value);

  /// `GET …/return-work/by-parcel-invoice` (D35 ②).
  Future<List<ClaimWorkModel>> claimsByParcelInvoice(String value);

  /// `GET …/return-work/shipped-orders` (D35 ③).
  Future<List<ShippedOrderModel>> shippedOrders();

  /// `GET …/return-work/orders/{orderId}` (D35 ③).
  Future<List<ClaimWorkModel>> claimsByOrder(int orderId);

  /// `POST …/return-work` (D35 ④).
  Future<void> returnWork(String movedOn, List<ClaimWorkLineRequest> lines);

  /// `GET …/exchange-work/by-reship-invoice` (D35 ⑥).
  Future<List<ClaimWorkModel>> claimsByReshipInvoice(String value);

  /// `GET …/exchange-work/open` (D35 ⑥).
  Future<List<ClaimWorkModel>> openExchanges();

  /// `POST …/exchange-work` (D35 ⑦).
  Future<void> exchangeWork(String movedOn, List<ClaimWorkLineRequest> lines);
}
