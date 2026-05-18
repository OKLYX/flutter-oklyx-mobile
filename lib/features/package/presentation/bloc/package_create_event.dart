import 'package:equatable/equatable.dart';

abstract class PackageCreateEvent extends Equatable {
  const PackageCreateEvent();
}

class PackageTypeChanged extends PackageCreateEvent {
  final String type;

  const PackageTypeChanged(this.type);

  @override
  List<Object> get props => [type];
}

class PackageCostChanged extends PackageCreateEvent {
  final String cost;

  const PackageCostChanged(this.cost);

  @override
  List<Object> get props => [cost];
}

class PackageEffectiveDateChanged extends PackageCreateEvent {
  final String effectiveDate;

  const PackageEffectiveDateChanged(this.effectiveDate);

  @override
  List<Object> get props => [effectiveDate];
}

class PackageIsDefaultChanged extends PackageCreateEvent {
  final bool isDefault;

  const PackageIsDefaultChanged(this.isDefault);

  @override
  List<Object> get props => [isDefault];
}

class CreatePackageRequested extends PackageCreateEvent {
  const CreatePackageRequested();

  @override
  List<Object> get props => [];
}

class ResetCreateForm extends PackageCreateEvent {
  const ResetCreateForm();

  @override
  List<Object> get props => [];
}
