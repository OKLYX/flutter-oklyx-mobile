sealed class CommissionRateDetailEvent {}

class FetchCommissionRateDetail extends CommissionRateDetailEvent {
  final int id;
  FetchCommissionRateDetail(this.id);
}

class StartEditingCommissionRate extends CommissionRateDetailEvent {}

class PlatformChanged extends CommissionRateDetailEvent {
  final String platform;
  PlatformChanged(this.platform);
}

class CategoryChanged extends CommissionRateDetailEvent {
  final int? categoryId;
  CategoryChanged(this.categoryId);
}

class RateChanged extends CommissionRateDetailEvent {
  final String rate;
  RateChanged(this.rate);
}

class UpdateCommissionRateSubmitted extends CommissionRateDetailEvent {}

class CancelEditing extends CommissionRateDetailEvent {}

class ConfirmDeleteCommissionRate extends CommissionRateDetailEvent {
  final int id;
  ConfirmDeleteCommissionRate(this.id);
}
