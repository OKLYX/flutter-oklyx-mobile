import 'package:equatable/equatable.dart';

abstract class SellerDetailEvent extends Equatable {
  const SellerDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadSellerDetail extends SellerDetailEvent {
  final int sellerId;

  const LoadSellerDetail(this.sellerId);

  @override
  List<Object?> get props => [sellerId];
}
