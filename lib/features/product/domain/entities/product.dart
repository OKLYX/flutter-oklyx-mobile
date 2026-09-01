import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String productName;
  final String? barcodeId;
  final String? brand;
  final int? price;
  final String? store;
  final String? netContentUnit;
  final String? packageHeight;
  final String? packageLength;
  final String? packageWidth;
  final String? netContent;
  final String? description;
  final String? name;
  final String? imageUrl;
  final bool active;
  final String createdDate;
  final String modifiedDate;

  const Product({
    required this.id,
    required this.productName,
    this.barcodeId,
    this.brand,
    this.price,
    this.store,
    this.netContentUnit,
    this.packageHeight,
    this.packageLength,
    this.packageWidth,
    this.netContent,
    this.description,
    this.name,
    this.imageUrl,
    required this.active,
    required this.createdDate,
    required this.modifiedDate,
  });

  @override
  List<Object?> get props => [
    id,
    productName,
    barcodeId,
    brand,
    price,
    store,
    netContentUnit,
    packageHeight,
    packageLength,
    packageWidth,
    netContent,
    description,
    name,
    imageUrl,
    active,
    createdDate,
    modifiedDate,
  ];
}
