import '../../domain/entities/commission_rate.dart';

sealed class CommissionRateCreateState {}

class CommissionRateCreateInitial extends CommissionRateCreateState {}

class CommissionRateCreateLoading extends CommissionRateCreateState {}

class CommissionRateCreateSuccess extends CommissionRateCreateState {
  final CommissionRate commissionRate;

  CommissionRateCreateSuccess(this.commissionRate);
}

class CommissionRateCreateError extends CommissionRateCreateState {
  final String message;

  CommissionRateCreateError(this.message);
}
