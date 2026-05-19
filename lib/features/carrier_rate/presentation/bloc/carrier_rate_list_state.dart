import 'package:flutter_oklyn_mobile/features/carrier_rate/domain/entities/carrier_rate.dart';

abstract class CarrierRateListState {}

class CarrierRateListInitial extends CarrierRateListState {}

class CarrierRateListLoading extends CarrierRateListState {}

class CarrierRateListLoaded extends CarrierRateListState {
  final List<CarrierRate> carrierRates;
  CarrierRateListLoaded({required this.carrierRates});
}

class CarrierRateListEmpty extends CarrierRateListState {}

class CarrierRateListError extends CarrierRateListState {
  final String message;
  CarrierRateListError({required this.message});
}
