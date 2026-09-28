import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/purchase_place.dart';

sealed class PurchasePlaceState extends Equatable {
  const PurchasePlaceState();

  @override
  List<Object?> get props => [];
}

class PurchasePlaceInitial extends PurchasePlaceState {
  const PurchasePlaceInitial();
}

class PurchasePlaceLoading extends PurchasePlaceState {
  const PurchasePlaceLoading();
}

class PurchasePlaceLoaded extends PurchasePlaceState {
  final List<PurchasePlace> places;

  const PurchasePlaceLoaded(this.places);

  @override
  List<Object?> get props => [places];
}

class PurchasePlaceError extends PurchasePlaceState {
  final String message;

  const PurchasePlaceError(this.message);

  @override
  List<Object?> get props => [message];
}
