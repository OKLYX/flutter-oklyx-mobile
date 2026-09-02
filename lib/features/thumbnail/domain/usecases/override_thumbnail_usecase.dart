import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product_thumbnail.dart';
import '../repositories/thumbnail_repository.dart';

class OverrideThumbnailUseCase {
  final ThumbnailRepository repository;

  OverrideThumbnailUseCase({required this.repository});

  Future<Either<Failure, ProductThumbnail>> call({
    required int productId,
    required int sellerId,
    required File file,
  }) {
    return repository.overrideThumbnail(productId, sellerId, file);
  }
}
