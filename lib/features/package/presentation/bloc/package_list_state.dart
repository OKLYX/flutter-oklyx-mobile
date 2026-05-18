import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

abstract class PackageListState {}

class PackageListInitial extends PackageListState {}

class PackageListLoading extends PackageListState {}

class PackageListLoaded extends PackageListState {
  final List<Package> packages;

  PackageListLoaded({required this.packages});
}

class PackageListEmpty extends PackageListState {}

class PackageListError extends PackageListState {
  final String message;

  PackageListError({required this.message});
}
