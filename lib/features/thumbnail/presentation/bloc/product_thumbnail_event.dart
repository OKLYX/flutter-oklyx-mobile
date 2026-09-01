import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProductThumbnailEvent extends Equatable {
  const ProductThumbnailEvent();

  @override
  List<Object?> get props => [];
}

/// Loads thumbnails + sellers + default template fields in parallel and seeds
/// initial field values (brandName/productName auto-filled from the product).
class LoadThumbnails extends ProductThumbnailEvent {
  final int productId;
  final String? productBrand;
  final String? productName;

  const LoadThumbnails({
    required this.productId,
    this.productBrand,
    this.productName,
  });

  @override
  List<Object?> get props => [productId, productBrand, productName];
}

/// Updates a single generation-panel field value (no reload — state only).
class UpdateFieldValue extends ProductThumbnailEvent {
  final String key;
  final String value;

  const UpdateFieldValue(this.key, this.value);

  @override
  List<Object?> get props => [key, value];
}

/// Generate / regenerate a seller thumbnail using the current fieldValues.
class GenerateThumbnail extends ProductThumbnailEvent {
  final int sellerId;

  const GenerateThumbnail(this.sellerId);

  @override
  List<Object?> get props => [sellerId];
}

/// Manual override with a picked image file.
class OverrideThumbnail extends ProductThumbnailEvent {
  final int sellerId;
  final File file;

  const OverrideThumbnail(this.sellerId, this.file);

  @override
  List<Object?> get props => [sellerId, file];
}

class DeleteThumbnail extends ProductThumbnailEvent {
  final int sellerId;

  const DeleteThumbnail(this.sellerId);

  @override
  List<Object?> get props => [sellerId];
}
