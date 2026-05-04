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
