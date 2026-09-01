import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/product_thumbnail.dart';
import '../repositories/thumbnail_repository.dart';

class GenerateThumbnailUseCase {
  final ThumbnailRepository repository;

  GenerateThumbnailUseCase({required this.repository});

  Future<Either<Failure, ProductThumbnail>> call({
    required int productId,
    required int sellerId,
    required Map<String, String> fieldValues,
  }) {
    return repository.generate(productId, sellerId, fieldValues);
  }
}
