import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_page.dart';
import 'product_model.dart';

class ProductPageModel {
  final List<ProductModel> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;
  final bool first;
  final bool last;

  ProductPageModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
    required this.first,
    required this.last,
  });

  factory ProductPageModel.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List<dynamic>?)
            ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProductPageModel(
      content: contentList,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      pageNumber: (json['pageable'] as Map<String, dynamic>?)?['pageNumber'] as int? ?? json['number'] as int? ?? 0,
      pageSize: json['size'] as int? ?? 20,
      first: json['first'] as bool? ?? false,
      last: json['last'] as bool? ?? false,
    );
  }

  ProductPage toDomain() => ProductPage(
    content: content.map((model) => model.toDomain()).toList(),
    totalElements: totalElements,
    totalPages: totalPages,
    pageNumber: pageNumber,
    pageSize: pageSize,
    first: first,
    last: last,
  );
}
