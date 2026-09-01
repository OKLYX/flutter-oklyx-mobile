import 'package:equatable/equatable.dart';

import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/product_thumbnail.dart';
import '../../domain/entities/template_field.dart';

abstract class ProductThumbnailState extends Equatable {
  const ProductThumbnailState();

  @override
  List<Object?> get props => [];
}

class ProductThumbnailInitial extends ProductThumbnailState {
  const ProductThumbnailInitial();
}

class ProductThumbnailLoading extends ProductThumbnailState {
  const ProductThumbnailLoading();
}

/// Full error screen (Load failure only). Action failures keep [Loaded].
class ProductThumbnailError extends ProductThumbnailState {
  final String message;

  const ProductThumbnailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductThumbnailLoaded extends ProductThumbnailState {
  final int productId;
  final List<ProductThumbnail> thumbnails;
  final List<Seller> sellers;
  final List<TemplateField> fields;

  /// key → current value for the generation panel.
  final Map<String, String> fieldValues;

  /// Seller id of the in-flight action (spinner target). Null = idle.
  final int? actionSellerId;

  /// Transient message for a failed action (Generate/Override/Delete) — shown as
  /// a floating SnackBar. Cleared at the start of the next action.
  final String? actionError;

  const ProductThumbnailLoaded({
    required this.productId,
    required this.thumbnails,
    required this.sellers,
    required this.fields,
    required this.fieldValues,
    this.actionSellerId,
    this.actionError,
  });

  ProductThumbnailLoaded copyWith({
    List<ProductThumbnail>? thumbnails,
    List<Seller>? sellers,
    List<TemplateField>? fields,
    Map<String, String>? fieldValues,
    int? actionSellerId,
    bool clearActionSellerId = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return ProductThumbnailLoaded(
      productId: productId,
      thumbnails: thumbnails ?? this.thumbnails,
      sellers: sellers ?? this.sellers,
      fields: fields ?? this.fields,
      fieldValues: fieldValues ?? this.fieldValues,
      actionSellerId:
          clearActionSellerId ? null : (actionSellerId ?? this.actionSellerId),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
        productId,
        thumbnails,
        sellers,
        fields,
        fieldValues,
        actionSellerId,
        actionError,
      ];
}
