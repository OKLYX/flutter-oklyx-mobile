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

class PackageWidthChanged extends PackageCreateEvent {
  final String width;

  const PackageWidthChanged(this.width);

  @override
  List<Object> get props => [width];
}

class PackageLengthChanged extends PackageCreateEvent {
  final String length;

  const PackageLengthChanged(this.length);

  @override
  List<Object> get props => [length];
}

class PackageHeightChanged extends PackageCreateEvent {
  final String height;

  const PackageHeightChanged(this.height);

  @override
  List<Object> get props => [height];
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
