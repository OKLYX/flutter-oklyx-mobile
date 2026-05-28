import '../models/commission_rate_model.dart';

abstract class CommissionRateRemoteDataSource {
  Future<List<CommissionRateModel>> getCommissionRates();
  Future<CommissionRateModel> getCommissionRate(int id);
  Future<CommissionRateModel> createCommissionRate(Map<String, dynamic> params);
  Future<CommissionRateModel> updateCommissionRate(int id, Map<String, dynamic> params);
  Future<void> deleteCommissionRate(int id);
}
