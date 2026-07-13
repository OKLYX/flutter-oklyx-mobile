abstract class CarrierRateDetailEvent {}

class FetchCarrierRateDetail extends CarrierRateDetailEvent {
  final int id;
  FetchCarrierRateDetail(this.id);
}

class LoadCarriersDetail extends CarrierRateDetailEvent {}

class CarrierIdDetailChanged extends CarrierRateDetailEvent {
  final int carrierId;
  CarrierIdDetailChanged(this.carrierId);
}

class TypeDetailChanged extends CarrierRateDetailEvent {
  final String type;
  TypeDetailChanged(this.type);
}

class CostDetailChanged extends CarrierRateDetailEvent {
  final String cost;
  CostDetailChanged(this.cost);
}

class EffectiveDateDetailChanged extends CarrierRateDetailEvent {
  final String date;
  EffectiveDateDetailChanged(this.date);
}

class IsDefaultDetailChanged extends CarrierRateDetailEvent {
  final bool isDefault;
  IsDefaultDetailChanged(this.isDefault);
}

class UpdateCarrierRateSubmitted extends CarrierRateDetailEvent {
  final int id;
  UpdateCarrierRateSubmitted(this.id);
}

class ConfirmDeleteCarrierRate extends CarrierRateDetailEvent {
  final int id;
  ConfirmDeleteCarrierRate(this.id);
}
