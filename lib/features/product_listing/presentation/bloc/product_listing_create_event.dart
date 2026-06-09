import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product.dart';
import '../bloc/product_listing_create_state.dart';

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

class FetchLookupData extends ProductListingCreateEvent {
  const FetchLookupData();

  @override
  List<Object?> get props => [];
}

class SearchProducts extends ProductListingCreateEvent {
  final String query;

  const SearchProducts({required this.query});

  @override
  List<Object?> get props => [query];
}

class SelectProduct extends ProductListingCreateEvent {
  final Product product;

  const SelectProduct({required this.product});

  @override
  List<Object?> get props => [product];
}

class RemoveProduct extends ProductListingCreateEvent {
  final int productId;

  const RemoveProduct({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class AddOption extends ProductListingCreateEvent {
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;
  final Map<int, int> productQuantities;

  const AddOption({
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
    required this.productQuantities,
  });

  @override
  List<Object?> get props => [optionName, sellingPrice, platformOptionId, productQuantities];
}

class UpdateOption extends ProductListingCreateEvent {
  final num optionId;
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;
  final Map<int, int> productQuantities;

  const UpdateOption({
    required this.optionId,
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
    required this.productQuantities,
  });

  @override
  List<Object?> get props =>
      [optionId, optionName, sellingPrice, platformOptionId, productQuantities];
}

class RemoveOption extends ProductListingCreateEvent {
  final num optionId;

  const RemoveOption({required this.optionId});

  @override
  List<Object?> get props => [optionId];
}

class UpdateCommissionRate extends ProductListingCreateEvent {
  final double rate;

  const UpdateCommissionRate({required this.rate});

  @override
  List<Object?> get props => [rate];
}
