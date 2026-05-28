sealed class CommissionRateDetailEvent {}

class FetchCommissionRateDetail extends CommissionRateDetailEvent {
  final int id;

  FetchCommissionRateDetail(this.id);
}

class UpdateCommissionRate extends CommissionRateDetailEvent {
  final int id;
  final String? platform;
  final int? categoryId;
  final double? rate;

  UpdateCommissionRate({
    required this.id,
    this.platform,
    this.categoryId,
    this.rate,
  });
}

class DeleteCommissionRate extends CommissionRateDetailEvent {
  final int id;

  DeleteCommissionRate(this.id);
}
