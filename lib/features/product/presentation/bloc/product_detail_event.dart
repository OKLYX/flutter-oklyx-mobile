import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/product/domain/entities/unit.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductDetail extends ProductDetailEvent {
  final int productId;

  const LoadProductDetail(this.productId);

  @override
  List<Object?> get props => [productId];
}

class RetryLoadProductDetail extends ProductDetailEvent {
  final int productId;

  const RetryLoadProductDetail(this.productId);

  @override
  List<Object?> get props => [productId];
}

class EditModeToggled extends ProductDetailEvent {
  const EditModeToggled();

  @override
  List<Object?> get props => [];
}

class UpdateProductRequested extends ProductDetailEvent {
  final String productName;
  final String? brand;
  final String? description;
  final int? price;
  final String? store;
  final Unit? netContentUnit;
  final double? packageHeight;
  final double? packageLength;
  final double? packageWidth;
  final double? netContent;

  const UpdateProductRequested({
    required this.productName,
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

class DeleteProductRequested extends ProductDetailEvent {
  const DeleteProductRequested();

  @override
  List<Object?> get props => [];
}

class UploadImageRequested extends ProductDetailEvent {
  final File imageFile;

  const UploadImageRequested(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class DeleteImageRequested extends ProductDetailEvent {
  const DeleteImageRequested();

  @override
  List<Object?> get props => [];
}
