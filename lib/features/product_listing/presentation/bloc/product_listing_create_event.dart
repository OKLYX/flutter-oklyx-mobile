import 'package:equatable/equatable.dart';

abstract class ProductListingCreateEvent extends Equatable {
  const ProductListingCreateEvent();
}

class ResetCreateForm extends ProductListingCreateEvent {
  const ResetCreateForm();

  @override
  List<Object?> get props => [];
}

class UpdateFormField extends ProductListingCreateEvent {
  final String field;
  final String value;

  const UpdateFormField({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}

class SubmitProductListingCreate extends ProductListingCreateEvent {
  const SubmitProductListingCreate();

  @override
  List<Object?> get props => [];
}
