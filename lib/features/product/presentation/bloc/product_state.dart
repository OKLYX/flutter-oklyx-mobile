import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final bool hasMore;
  final int currentPage;

  const ProductLoaded({
    required this.products,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [products, hasMore, currentPage];
}

class ProductLoadingMore extends ProductState {
  final List<Product> products;
  final int currentPage;

  const ProductLoadingMore({
    required this.products,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [products, currentPage];
}

class ProductError extends ProductState {
  final String message;

  const ProductError({required this.message});

  @override
  List<Object?> get props => [message];
}
