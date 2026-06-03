import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';

abstract class SellerDetailState extends Equatable {
  const SellerDetailState();

  @override
  List<Object?> get props => [];
}

class SellerDetailInitial extends SellerDetailState {
  const SellerDetailInitial();
}

class SellerDetailLoading extends SellerDetailState {
  const SellerDetailLoading();
}

class SellerDetailLoaded extends SellerDetailState {
  final Seller seller;

  const SellerDetailLoaded(this.seller);

  @override
  List<Object?> get props => [seller];
}

class SellerDetailError extends SellerDetailState {
  final String message;

  const SellerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
