import 'package:formz/formz.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';
import 'carrier_rate_create_state.dart';

abstract class CarrierRateDetailState {}

class CarrierRateDetailLoading extends CarrierRateDetailState {}

class CarrierRateDetailLoaded extends CarrierRateDetailState {
  final int? carrierId;
  final List<Carrier> carriers;
  final bool carriersLoading;
  final TypeForm type;
  final CostForm cost;
  final EffectiveDateForm effectiveDate;
  final bool isDefault;
  final bool isSubmitting;
  final String? error;

  CarrierRateDetailLoaded({
    this.carrierId,
    this.carriers = const [],
    this.carriersLoading = false,
    this.type = const TypeForm.pure(),
    this.cost = const CostForm.pure(),
    this.effectiveDate = const EffectiveDateForm.pure(),
    this.isDefault = false,
    this.isSubmitting = false,
    this.error,
  });

  bool get isValid =>
      carrierId != null && Formz.validate([type, cost, effectiveDate]);

  CarrierRateDetailLoaded copyWith({
    int? carrierId,
    List<Carrier>? carriers,
    bool? carriersLoading,
    TypeForm? type,
    CostForm? cost,
    EffectiveDateForm? effectiveDate,
    bool? isDefault,
    bool? isSubmitting,
    String? error,
  }) =>
      CarrierRateDetailLoaded(
        carrierId: carrierId ?? this.carrierId,
        carriers: carriers ?? this.carriers,
        carriersLoading: carriersLoading ?? this.carriersLoading,
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

class CarrierRateDetailDeleting extends CarrierRateDetailState {}

class CarrierRateDetailDeleteSuccess extends CarrierRateDetailState {}
