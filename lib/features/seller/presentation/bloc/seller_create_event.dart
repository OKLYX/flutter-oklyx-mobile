import 'package:equatable/equatable.dart';

abstract class SellerCreateEvent extends Equatable {
  const SellerCreateEvent();
}

class ResetCreateForm extends SellerCreateEvent {
  const ResetCreateForm();

  @override
  List<Object?> get props => [];
}

class UpdateFormField extends SellerCreateEvent {
  final String field; // 'sellerName' or 'businessRegistration'
  final String value;

  const UpdateFormField({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}

class SubmitSellerCreate extends SellerCreateEvent {
  const SubmitSellerCreate();

  @override
  List<Object?> get props => [];
}
