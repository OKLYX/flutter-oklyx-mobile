import '../../domain/entities/commission_rate.dart';

sealed class CommissionRateListState {}

class CommissionRateListInitial extends CommissionRateListState {}

class CommissionRateListLoading extends CommissionRateListState {}

class CommissionRateListSuccess extends CommissionRateListState {
  final List<CommissionRate> commissionRates;

  CommissionRateListSuccess(this.commissionRates);
}

class CommissionRateListError extends CommissionRateListState {
  final String message;

  CommissionRateListError(this.message);
}
