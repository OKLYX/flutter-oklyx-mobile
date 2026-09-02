import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../repositories/thumbnail_repository.dart';

class DeleteThumbnailUseCase {
  final ThumbnailRepository repository;

  DeleteThumbnailUseCase({required this.repository});

  Future<Either<Failure, void>> call({
    required int productId,
    required int sellerId,
  }) {
    return repository.delete(productId, sellerId);
  }
}
