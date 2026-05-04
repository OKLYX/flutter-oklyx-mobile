import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';

sealed class ProductRegisterState extends Equatable {
  const ProductRegisterState();
}

class ProductRegisterInitial extends ProductRegisterState {
  @override
  List<Object?> get props => [];
}

class ProductRegisterLoading extends ProductRegisterState {
  @override
  List<Object?> get props => [];
}

class BarcodeCheckLoading extends ProductRegisterState {
  @override
  List<Object?> get props => [];
}

class BarcodeAvailable extends ProductRegisterState {
  @override
  List<Object?> get props => [];
}

class BarcodeUnavailable extends ProductRegisterState {
  final String message;

  const BarcodeUnavailable(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductRegisterSuccess extends ProductRegisterState {
  final Product product;

  const ProductRegisterSuccess(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductRegisterError extends ProductRegisterState {
  final String message;

  const ProductRegisterError(this.message);

  @override
  List<Object?> get props => [message];
}

class BarcodeCheckError extends ProductRegisterState {
  final String message;

  const BarcodeCheckError(this.message);

  @override
  List<Object?> get props => [message];
}
