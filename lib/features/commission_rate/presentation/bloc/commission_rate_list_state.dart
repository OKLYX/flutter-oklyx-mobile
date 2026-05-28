import '../../domain/entities/commission_rate.dart';

sealed class CommissionRateListState {}

class CommissionRateListInitial extends CommissionRateListState {}

class CommissionRateListLoading extends CommissionRateListState {}

class CommissionRateListLoaded extends CommissionRateListState {
  final List<CommissionRate> commissionRates;

  CommissionRateListLoaded({required this.commissionRates});
}

class CommissionRateListEmpty extends CommissionRateListState {}

class CommissionRateListError extends CommissionRateListState {
  final String message;

  CommissionRateListError({required this.message});
}
