import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';

sealed class PackageDetailState {}

class PackageDetailInitial extends PackageDetailState {}

class PackageDetailLoading extends PackageDetailState {}

class PackageDetailLoaded extends PackageDetailState {
  final Package package;
  PackageDetailLoaded(this.package);
}

class PackageDetailEditing extends PackageDetailState {
  final Package originalPackage;
  final Map<String, dynamic> editingData;
  final Map<String, String> validationErrors;

  PackageDetailEditing({
    required this.originalPackage,
    required this.editingData,
    this.validationErrors = const {},
  });
}

class PackageDetailSubmitting extends PackageDetailState {}

class PackageDetailUpdateSuccess extends PackageDetailState {}

class PackageDetailConfirmingDelete extends PackageDetailState {
  final Package package;

  PackageDetailConfirmingDelete({required this.package});
}

class PackageDetailDeleting extends PackageDetailState {}

class PackageDetailDeleteSuccess extends PackageDetailState {}

class PackageDetailError extends PackageDetailState {
  final String message;
  PackageDetailError(this.message);
}
