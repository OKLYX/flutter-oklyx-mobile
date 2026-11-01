import 'dart:io';

import 'package:equatable/equatable.dart';

sealed class ProductImageGalleryEvent extends Equatable {
  const ProductImageGalleryEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the gallery of [productId]; every later event works on this product.
class ProductImagesRequested extends ProductImageGalleryEvent {
  final int productId;

  const ProductImagesRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Appends [files] (already checked: JPEG/PNG, 20MB or less).
class ProductImagesAdded extends ProductImageGalleryEvent {
  final List<File> files;

  const ProductImagesAdded(this.files);

  @override
  List<Object?> get props => [files.map((f) => f.path).toList()];
}

class ProductImageReplaced extends ProductImageGalleryEvent {
  final int imageId;
  final File file;

  const ProductImageReplaced({required this.imageId, required this.file});

  @override
  List<Object?> get props => [imageId, file.path];
}

/// Swaps the photo at [index] with its neighbour ([direction] = -1 or 1).
class ProductImageMoved extends ProductImageGalleryEvent {
  final int index;
  final int direction;

  const ProductImageMoved({required this.index, required this.direction});

  @override
  List<Object?> get props => [index, direction];
}

class ProductImageDeleted extends ProductImageGalleryEvent {
  final int imageId;

  const ProductImageDeleted(this.imageId);

  @override
  List<Object?> get props => [imageId];
}
