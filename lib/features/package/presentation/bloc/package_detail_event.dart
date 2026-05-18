sealed class PackageDetailEvent {}

class LoadPackageDetail extends PackageDetailEvent {
  final int packageId;
  LoadPackageDetail(this.packageId);
}

class StartEditingPackage extends PackageDetailEvent {}

class UpdateFormField extends PackageDetailEvent {
  final String field;
  final dynamic value;
  UpdateFormField({required this.field, required this.value});
}

class SubmitPackageUpdate extends PackageDetailEvent {}
