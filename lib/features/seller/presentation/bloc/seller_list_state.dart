import 'package:equatable/equatable.dart';

abstract class SellerListState extends Equatable {
  const SellerListState();
  @override
  List<Object?> get props => [];
}

class SellerListInitial extends SellerListState {
  const SellerListInitial();
}

class SellerListLoading extends SellerListState {
  const SellerListLoading();
}

class SellerListLoaded extends SellerListState {
  final List<dynamic> sellers;
  const SellerListLoaded(this.sellers);
  @override
  List<Object?> get props => [sellers];
}

class SellerListEmpty extends SellerListState {
  const SellerListEmpty();
}

class SellerListError extends SellerListState {
  final String message;
  const SellerListError(this.message);
  @override
  List<Object?> get props => [message];
}
