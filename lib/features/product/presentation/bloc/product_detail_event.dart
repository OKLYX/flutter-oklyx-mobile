import 'package:equatable/equatable.dart';

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
  final String? unit;
  final double? volumeHeight;
  final double? volumeLong;
  final double? volumeShort;
  final double? weight;

  const UpdateProductRequested({
    required this.productName,
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

class DeleteProductRequested extends ProductDetailEvent {
  const DeleteProductRequested();

  @override
  List<Object?> get props => [];
}
