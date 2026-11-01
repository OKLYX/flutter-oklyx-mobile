import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product_image.dart';

/// One state for the whole gallery (copyWith), like `PurchaseListLoaded`.
///
/// [busy] blocks every button while a write is in flight. [actionError] is
/// shown once as a failure toast; [errorSeq] grows with every failure so the
/// same message twice still reaches the listener.
class ProductImageGalleryState extends Equatable {
  final List<ProductImage> images;
  final bool isLoading;
  final bool busy;
  final String? loadError;
  final String? actionError;
  final int errorSeq;

  const ProductImageGalleryState({
    this.images = const [],
    this.isLoading = true,
    this.busy = false,
    this.loadError,
    this.actionError,
    this.errorSeq = 0,
  });

  ProductImageGalleryState copyWith({
    List<ProductImage>? images,
    bool? isLoading,
    bool? busy,
    String? loadError,
    bool clearLoadError = false,
    String? actionError,
  }) =>
      ProductImageGalleryState(
        images: images ?? this.images,
        isLoading: isLoading ?? this.isLoading,
        busy: busy ?? this.busy,
        loadError: clearLoadError ? null : (loadError ?? this.loadError),
        actionError: actionError,
        errorSeq: actionError == null ? errorSeq : errorSeq + 1,
      );

  @override
  List<Object?> get props =>
      [images, isLoading, busy, loadError, actionError, errorSeq];
}
