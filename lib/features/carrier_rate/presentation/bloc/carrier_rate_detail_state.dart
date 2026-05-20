import 'package:formz/formz.dart';
import 'carrier_rate_create_state.dart';

abstract class CarrierRateDetailState {}

class CarrierRateDetailLoading extends CarrierRateDetailState {}

class CarrierRateDetailLoaded extends CarrierRateDetailState {
  final CarrierForm carrier;
  final TypeForm type;
  final CostForm cost;
  final EffectiveDateForm effectiveDate;
  final bool isDefault;
  final bool isSubmitting;
  final String? error;

  CarrierRateDetailLoaded({
    this.carrier = const CarrierForm.pure(),
    this.type = const TypeForm.pure(),
    this.cost = const CostForm.pure(),
    this.effectiveDate = const EffectiveDateForm.pure(),
    this.isDefault = false,
    this.isSubmitting = false,
    this.error,
  });

  bool get isValid => Formz.validate([carrier, type, cost, effectiveDate]);

  CarrierRateDetailLoaded copyWith({
    CarrierForm? carrier,
    TypeForm? type,
    CostForm? cost,
    EffectiveDateForm? effectiveDate,
    bool? isDefault,
    bool? isSubmitting,
    String? error,
  }) =>
      CarrierRateDetailLoaded(
        carrier: carrier ?? this.carrier,
        type: type ?? this.type,
        cost: cost ?? this.cost,
        effectiveDate: effectiveDate ?? this.effectiveDate,
        isDefault: isDefault ?? this.isDefault,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );
}

class CarrierRateDetailError extends CarrierRateDetailState {
  final String message;
  CarrierRateDetailError(this.message);
}

class CarrierRateDetailSuccess extends CarrierRateDetailState {}
