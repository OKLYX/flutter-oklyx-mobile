import 'package:formz/formz.dart';

class CarrierForm extends FormzInput<String, String> {
  const CarrierForm.pure() : super.pure('');
  const CarrierForm.dirty({String value = ''}) : super.dirty(value);

  @override
  String? validator(String value) {
    if (value.isEmpty) return '배송사를 입력하세요';
    if (value.length > 100) return '100자 이내';
    return null;
  }

  String? get error => validator(value);
}

class TypeForm extends FormzInput<String, String> {
  const TypeForm.pure() : super.pure('');
  const TypeForm.dirty({String value = ''}) : super.dirty(value);

  @override
  String? validator(String value) {
    if (value.isEmpty) return '타입을 입력하세요';
    if (value.length > 50) return '50자 이내';
    return null;
  }

  String? get error => validator(value);
}

class CostForm extends FormzInput<double, String> {
  const CostForm.pure() : super.pure(0.0);
  const CostForm.dirty({double value = 0.0}) : super.dirty(value);

  @override
  String? validator(double value) {
    if (value <= 0) return '비용은 양수여야 합니다';
    return null;
  }

  String? get error => validator(value);
}

class EffectiveDateForm extends FormzInput<String, String> {
  const EffectiveDateForm.pure() : super.pure('');
  const EffectiveDateForm.dirty({String value = ''}) : super.dirty(value);

  @override
  String? validator(String value) {
    if (value.isEmpty) return '유효일을 선택하세요';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'YYYY-MM-DD 형식';
    }
    return null;
  }

  String? get error => validator(value);
}

abstract class CarrierRateCreateState {}

class CarrierRateCreateInitial extends CarrierRateCreateState {
  final CarrierForm carrier;
  final TypeForm type;
  final CostForm cost;
  final EffectiveDateForm effectiveDate;
  final bool isDefault;
  final bool isSubmitting;
  final String? error;

  CarrierRateCreateInitial({
    this.carrier = const CarrierForm.pure(),
    this.type = const TypeForm.pure(),
    this.cost = const CostForm.pure(),
    this.effectiveDate = const EffectiveDateForm.pure(),
    this.isDefault = false,
    this.isSubmitting = false,
    this.error,
  });

  bool get isValid => Formz.validate([carrier, type, cost, effectiveDate]);

  CarrierRateCreateInitial copyWith({
    CarrierForm? carrier,
    TypeForm? type,
    CostForm? cost,
    EffectiveDateForm? effectiveDate,
    bool? isDefault,
    bool? isSubmitting,
    String? error,
  }) =>
      CarrierRateCreateInitial(
        carrier: carrier ?? this.carrier,
        type: type ?? this.type,
        cost: cost ?? this.cost,
        effectiveDate: effectiveDate ?? this.effectiveDate,
        isDefault: isDefault ?? this.isDefault,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );
}

class CarrierRateCreateSuccess extends CarrierRateCreateState {}

class CarrierRateCreateError extends CarrierRateCreateState {
  final String message;
  CarrierRateCreateError(this.message);
}
