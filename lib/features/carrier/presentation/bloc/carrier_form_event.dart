import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';

abstract class CarrierFormEvent {}

class CreateCarrier extends CarrierFormEvent {
  final String name;
  final bool isActive;
  CreateCarrier({required this.name, required this.isActive});
}

class UpdateCarrier extends CarrierFormEvent {
  final int id;
  final String name;
  final bool isActive;
  UpdateCarrier({required this.id, required this.name, required this.isActive});
}

/// 활성/비활성 토글. PATCH full-replace 이므로 기존 name + 반전된 isActive 로 update 호출.
class ToggleActive extends CarrierFormEvent {
  final Carrier carrier;
  ToggleActive({required this.carrier});
}

class DeleteCarrier extends CarrierFormEvent {
  final int id;
  DeleteCarrier({required this.id});
}
