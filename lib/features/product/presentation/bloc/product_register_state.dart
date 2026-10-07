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

/// Image upload for barcode reading is in progress.
class BarcodeScanLoading extends ProductRegisterState {
  @override
  List<Object?> get props => [];
}

/// The server read [barcode] from the image.
class BarcodeScanSuccess extends ProductRegisterState {
  final String barcode;

  const BarcodeScanSuccess(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// The image was accepted but no readable barcode was found.
class BarcodeScanNotFound extends ProductRegisterState {
  @override
  List<Object?> get props => [];
}

/// Upload failed or the server rejected the image (400).
class BarcodeScanError extends ProductRegisterState {
  final String message;

  const BarcodeScanError(this.message);

  @override
  List<Object?> get props => [message];
}
