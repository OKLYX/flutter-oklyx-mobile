sealed class CommissionRateCreateEvent {}

class CreateCommissionRate extends CommissionRateCreateEvent {
  final String platform;
  final int? categoryId;
  final double rate;

  CreateCommissionRate({
    required this.platform,
    this.categoryId,
    required this.rate,
  });
}

class ResetCreateForm extends CommissionRateCreateEvent {}
