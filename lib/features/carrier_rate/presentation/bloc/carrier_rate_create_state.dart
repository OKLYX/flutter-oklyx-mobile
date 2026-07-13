import 'package:formz/formz.dart';
import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';

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
  final int? carrierId;
  final List<Carrier> carriers;
  final bool carriersLoading;
  final TypeForm type;
  final CostForm cost;
  final EffectiveDateForm effectiveDate;
  final bool isDefault;
  final bool isSubmitting;
  final String? error;

  CarrierRateCreateInitial({
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

  CarrierRateCreateInitial copyWith({
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
      CarrierRateCreateInitial(
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

class CarrierRateCreateSuccess extends CarrierRateCreateState {}

class CarrierRateCreateError extends CarrierRateCreateState {
  final String message;
  CarrierRateCreateError(this.message);
}
