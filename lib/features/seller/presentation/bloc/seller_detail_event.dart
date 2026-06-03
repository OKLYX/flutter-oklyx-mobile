import 'package:equatable/equatable.dart';

abstract class SellerDetailEvent extends Equatable {
  const SellerDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadSellerDetail extends SellerDetailEvent {
  final int sellerId;

  const LoadSellerDetail(this.sellerId);

  @override
  List<Object?> get props => [sellerId];
}

class StartEditingSeller extends SellerDetailEvent {
  const StartEditingSeller();
}

class UpdateSellerFormField extends SellerDetailEvent {
  final String field;
  final dynamic value;

  const UpdateSellerFormField({required this.field, required this.value});

  @override
  List<Object?> get props => [field, value];
}

class SubmitSellerUpdate extends SellerDetailEvent {
  const SubmitSellerUpdate();
}

class ConfirmDeleteSeller extends SellerDetailEvent {
  const ConfirmDeleteSeller();
}

class SubmitSellerUpdateDirect extends SellerDetailEvent {
  final String sellerName;
  final String businessRegistration;

  const SubmitSellerUpdateDirect({
    required this.sellerName,
    required this.businessRegistration,
  });

  @override
  List<Object?> get props => [sellerName, businessRegistration];
}
