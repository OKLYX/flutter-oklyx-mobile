import 'package:flutter_oklyn_mobile/features/carrier/domain/entities/carrier.dart';

abstract class CarrierListState {}

class CarrierListInitial extends CarrierListState {}

class CarrierListLoading extends CarrierListState {}

class CarrierListLoaded extends CarrierListState {
  final List<Carrier> carriers;
  CarrierListLoaded({required this.carriers});
}

class CarrierListEmpty extends CarrierListState {}

class CarrierListError extends CarrierListState {
  final String message;
  CarrierListError({required this.message});
}
