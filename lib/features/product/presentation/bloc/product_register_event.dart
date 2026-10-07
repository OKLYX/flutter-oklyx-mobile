import 'dart:io';

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
  final List<int> purchasePlaceIds;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;
  final int? countQuantity;
  final String? countUnit;

  const RegisterProductRequested({
    required this.productName,
    this.barcodeId,
    this.brand,
    this.description,
    this.price,
    this.purchasePlaceIds = const [],
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
    this.countQuantity,
    this.countUnit,
  });

  @override
  List<Object?> get props => [
    productName,
    barcodeId,
    brand,
    description,
    price,
    purchasePlaceIds,
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
    countQuantity,
    countUnit,
  ];
}

class CheckBarcodeRequested extends ProductRegisterEvent {
  final String barcodeId;

  const CheckBarcodeRequested(this.barcodeId);

  @override
  List<Object?> get props => [barcodeId];
}

/// Upload [image] so the server reads its barcode (image is not stored).
class ScanBarcodeFromImageRequested extends ProductRegisterEvent {
  final File image;

  const ScanBarcodeFromImageRequested(this.image);

  @override
  List<Object?> get props => [image.path];
}
