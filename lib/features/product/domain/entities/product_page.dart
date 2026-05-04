import 'package:equatable/equatable.dart';
import 'product.dart';

class ProductPage extends Equatable {
  final List<Product> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;
  final bool first;
  final bool last;

  const ProductPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
    required this.first,
    required this.last,
  });

  @override
  List<Object?> get props => [
    content,
    totalElements,
    totalPages,
    pageNumber,
    pageSize,
    first,
    last,
  ];
}
