sealed class CommissionRateCreateEvent {}

class PlatformSelected extends CommissionRateCreateEvent {
  final String platform;
  PlatformSelected(this.platform);
}

class CategorySelected extends CommissionRateCreateEvent {
  final int categoryId;
  CategorySelected(this.categoryId);
}

class RateChanged extends CommissionRateCreateEvent {
  final String rate;
  RateChanged(this.rate);
}

class CreateCommissionRateSubmitted extends CommissionRateCreateEvent {
  final String platform;
  final int? categoryId;
  final double rate;

  CreateCommissionRateSubmitted({
    required this.platform,
    this.categoryId,
    required this.rate,
  });
}

class ResetCreateForm extends CommissionRateCreateEvent {}
