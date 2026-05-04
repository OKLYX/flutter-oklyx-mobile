import 'package:equatable/equatable.dart';

sealed class ProductRegisterEvent extends Equatable {
  const ProductRegisterEvent();
}

class RegisterProductRequested extends ProductRegisterEvent {
  final String productName;
  final String barcodeId;
  final String? brand;
  final String? description;
  final int? price;
  final String? store;
  final String? unit;
  final double? volumeHeight;
  final double? volumeLong;
  final double? volumeShort;
  final double? weight;

  const RegisterProductRequested({
    required this.productName,
    required this.barcodeId,
    this.brand,
    this.description,
    this.price,
    this.store,
    this.unit,
    this.volumeHeight,
    this.volumeLong,
    this.volumeShort,
    this.weight,
  });

  @override
  List<Object?> get props => [
    productName,
    barcodeId,
    brand,
    description,
    price,
    store,
    unit,
    volumeHeight,
    volumeLong,
    volumeShort,
    weight,
  ];
}

class CheckBarcodeRequested extends ProductRegisterEvent {
  final String barcodeId;

  const CheckBarcodeRequested(this.barcodeId);

  @override
  List<Object?> get props => [barcodeId];
}
