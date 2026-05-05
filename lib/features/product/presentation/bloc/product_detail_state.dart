import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';

sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

class ProductDetailLoaded extends ProductDetailState {
  final Product product;

  const ProductDetailLoaded({required this.product});

  @override
  List<Object?> get props => [product];
}

class ProductDetailError extends ProductDetailState {
  final String message;

  const ProductDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProductDetailEditing extends ProductDetailState {
  final Product product;
  final String? errorMessage;

  const ProductDetailEditing({
    required this.product,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [product, errorMessage];
}

class ProductDetailUpdating extends ProductDetailState {
  const ProductDetailUpdating();
}

class ProductDetailUpdateSuccess extends ProductDetailState {
  final Product product;

  const ProductDetailUpdateSuccess({required this.product});

  @override
  List<Object?> get props => [product];
}

class ProductDetailUpdateError extends ProductDetailState {
  final String message;

  const ProductDetailUpdateError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProductDetailDeleting extends ProductDetailState {
  const ProductDetailDeleting();
}

class ProductDetailDeleteSuccess extends ProductDetailState {
  const ProductDetailDeleteSuccess();
}

class ProductDetailDeleteError extends ProductDetailState {
  final String message;

  const ProductDetailDeleteError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProductDetailImageUploading extends ProductDetailState {
  const ProductDetailImageUploading();
}

class ProductDetailImageDeleting extends ProductDetailState {
  const ProductDetailImageDeleting();
}

class ProductDetailImageError extends ProductDetailState {
  final String message;
  final Product product;

  const ProductDetailImageError({
    required this.message,
    required this.product,
  });

  @override
  List<Object?> get props => [message, product];
}
