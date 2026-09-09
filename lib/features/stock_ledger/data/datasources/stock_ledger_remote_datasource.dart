import '../models/outbound_order_model.dart';
import '../models/purchase_candidate_model.dart';
import '../models/return_candidate_model.dart';
import '../models/stock_balance_model.dart';
import '../models/stock_movement_model.dart';
import '../models/confirm_outbound_params.dart';
import '../models/record_movement_params.dart';

/// 실물 재고 원장 API (`/api/admin/stock/**`, PLAN 2609_28 D19 — ADMIN 전용).
///
/// ⚠️ 옛 `/api/stock`(StockLog)과 경로가 다르다. 이 기능은 그쪽을 호출하지 않는다.
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
}
