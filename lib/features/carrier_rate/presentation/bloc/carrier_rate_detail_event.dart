abstract class CarrierRateDetailEvent {}

class FetchCarrierRateDetail extends CarrierRateDetailEvent {
  final int id;
  FetchCarrierRateDetail(this.id);
}

class CarrierDetailChanged extends CarrierRateDetailEvent {
  final String carrier;
  CarrierDetailChanged(this.carrier);
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
