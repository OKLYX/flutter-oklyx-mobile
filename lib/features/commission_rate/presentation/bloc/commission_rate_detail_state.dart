import '../../domain/entities/commission_rate.dart';

sealed class CommissionRateDetailState {}

class CommissionRateDetailInitial extends CommissionRateDetailState {}

class CommissionRateDetailLoading extends CommissionRateDetailState {}

class CommissionRateDetailSuccess extends CommissionRateDetailState {
  final CommissionRate commissionRate;

  CommissionRateDetailSuccess(this.commissionRate);
}

class CommissionRateDetailError extends CommissionRateDetailState {
  final String message;

  CommissionRateDetailError(this.message);
}

class CommissionRateDetailUpdating extends CommissionRateDetailState {}

class CommissionRateDetailUpdateSuccess extends CommissionRateDetailState {
  final CommissionRate commissionRate;

  CommissionRateDetailUpdateSuccess(this.commissionRate);
}

class CommissionRateDetailDeleting extends CommissionRateDetailState {}

class CommissionRateDetailDeleteSuccess extends CommissionRateDetailState {}
