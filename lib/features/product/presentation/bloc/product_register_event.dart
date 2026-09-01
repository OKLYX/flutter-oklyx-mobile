import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';

sealed class ProductRegisterEvent extends Equatable {
  const ProductRegisterEvent();
}

class RegisterProductRequested extends ProductRegisterEvent {
  final String productName;
  final String? barcodeId;
  final String? brand;
  final String? description;
  final int? price;
  final String? store;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;

  const RegisterProductRequested({
    required this.productName,
    this.barcodeId,
    this.brand,
    this.description,
    this.price,
    this.store,
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
  });

  @override
  List<Object?> get props => [
    productName,
    barcodeId,
    brand,
    description,
    price,
    store,
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
  ];
}

class CheckBarcodeRequested extends ProductRegisterEvent {
  final String barcodeId;

  const CheckBarcodeRequested(this.barcodeId);

  @override
  List<Object?> get props => [barcodeId];
}
