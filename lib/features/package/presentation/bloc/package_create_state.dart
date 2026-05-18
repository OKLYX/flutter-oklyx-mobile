import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

abstract class PackageCreateState extends Equatable {
  const PackageCreateState();
}

class PackageCreateInitial extends PackageCreateState {
  @override
  List<Object> get props => [];
}

class PackageCreateLoading extends PackageCreateState {
  @override
  List<Object> get props => [];
}

class PackageCreateLoaded extends PackageCreateState {
  final String type;
  final String cost;
  final String effectiveDate;
  final bool isDefault;
  final bool isFormValid;

  const PackageCreateLoaded({
    required this.type,
    required this.cost,
    required this.effectiveDate,
    required this.isDefault,
    required this.isFormValid,
  });

  @override
  List<Object> get props => [
    type,
    cost,
    effectiveDate,
    isDefault,
    isFormValid,
  ];
}

class PackageCreateSuccess extends PackageCreateState {
  final Package createdPackage;

  const PackageCreateSuccess(this.createdPackage);

  @override
  List<Object> get props => [createdPackage];
}

class PackageCreateError extends PackageCreateState {
  final String message;

  const PackageCreateError(this.message);

  @override
  List<Object> get props => [message];
}
