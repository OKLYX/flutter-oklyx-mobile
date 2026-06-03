import 'package:equatable/equatable.dart';
import '../../domain/entities/seller.dart';

abstract class SellerCreateState extends Equatable {
  const SellerCreateState();
}

class SellerCreateLoaded extends SellerCreateState {
  final Map<String, String> formData; // {sellerName, businessRegistration}
  final Map<String, String?> validationErrors; // {field: errorMsg or null}

  const SellerCreateLoaded({required this.formData, this.validationErrors = const {}});

  @override
  List<Object?> get props => [formData, validationErrors];
}

class SellerCreateLoading extends SellerCreateState {
  const SellerCreateLoading();

  @override
  List<Object?> get props => [];
}

class SellerCreateSuccess extends SellerCreateState {
  final Seller seller;

  const SellerCreateSuccess(this.seller);

  @override
  List<Object?> get props => [seller];
}

class SellerCreateError extends SellerCreateState {
  final String message;

  const SellerCreateError(this.message);

  @override
  List<Object?> get props => [message];
}
