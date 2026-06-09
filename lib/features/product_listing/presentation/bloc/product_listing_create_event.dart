import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product.dart';
import '../../domain/entities/product_listing.dart';

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

/// 드롭다운용 lookup 데이터(판매자/카테고리/배송사/패키지/수수료율)를 로드한다.
///
/// [editListing] 가 주어지면(수정 모드) 로드 완료 후 같은 Loaded 상태에 기존
/// 판매상품 데이터를 함께 프리필한다. lookup + 프리필을 한 번의 emit으로 처리해
/// 순서 경합(프리필이 빈 폼으로 덮어써지는 문제)을 원천 차단한다.
/// 이 경우 이후 [SubmitProductListingCreate]는 create 대신 update를 호출한다.
class FetchLookupData extends ProductListingCreateEvent {
  final ProductListing? editListing;

  const FetchLookupData({this.editListing});

  @override
  List<Object?> get props => [editListing?.id];
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
