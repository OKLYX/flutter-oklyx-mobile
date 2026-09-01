import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product_thumbnail.dart';
import '../repositories/thumbnail_repository.dart';

class GetProductThumbnailsUseCase {
  final ThumbnailRepository repository;

  GetProductThumbnailsUseCase({required this.repository});

  Future<Either<Failure, List<ProductThumbnail>>> call(int productId) {
    return repository.getByProduct(productId);
  }
}
