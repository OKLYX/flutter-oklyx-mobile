import 'package:fpdart/fpdart.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import '../entities/template_field.dart';
import '../repositories/thumbnail_repository.dart';

class GetDefaultTemplateFieldsUseCase {
  final ThumbnailRepository repository;

  GetDefaultTemplateFieldsUseCase({required this.repository});

  Future<Either<Failure, List<TemplateField>>> call() {
    return repository.getDefaultTemplateFields();
  }
}
