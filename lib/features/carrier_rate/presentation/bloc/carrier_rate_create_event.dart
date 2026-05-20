abstract class CarrierRateCreateEvent {}

class CarrierChanged extends CarrierRateCreateEvent {
  final String carrier;
  CarrierChanged(this.carrier);
}

class TypeChanged extends CarrierRateCreateEvent {
  final String type;
  TypeChanged(this.type);
}

class CostChanged extends CarrierRateCreateEvent {
  final String cost;
  CostChanged(this.cost);
}

class EffectiveDateChanged extends CarrierRateCreateEvent {
  final String date;
  EffectiveDateChanged(this.date);
}

class IsDefaultChanged extends CarrierRateCreateEvent {
  final bool isDefault;
  IsDefaultChanged(this.isDefault);
}

class CreateCarrierRateSubmitted extends CarrierRateCreateEvent {}

class ResetCreateForm extends CarrierRateCreateEvent {}
