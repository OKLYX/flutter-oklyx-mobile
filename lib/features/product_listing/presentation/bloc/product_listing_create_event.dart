import 'package:equatable/equatable.dart';
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

/// 수정 제출. 등록(create) 분기는 제거됐다 - 판매상품은 마스터 상품을 통해서만 생긴다.
class SubmitProductListingCreate extends ProductListingCreateEvent {
  const SubmitProductListingCreate();

  @override
  List<Object?> get props => [];
}

/// 드롭다운용 lookup 데이터(판매자/카테고리/배송사/패키지/수수료율)를 로드한다.
///
/// [editListing] 로 로드 완료 후 같은 Loaded 상태에 기존 판매상품 데이터를 함께
/// 프리필한다. lookup + 프리필을 한 번의 emit으로 처리해 순서 경합(프리필이 빈 폼으로
/// 덮어써지는 문제)을 원천 차단한다.
class FetchLookupData extends ProductListingCreateEvent {
  final ProductListing? editListing;

  const FetchLookupData({this.editListing});

  @override
  List<Object?> get props => [editListing?.id];
}

/// 옵션 추가. 구성품은 입력하지 않는다 - 마스터 상품이 소유한다.
class AddOption extends ProductListingCreateEvent {
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;

  const AddOption({
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
  });

  @override
  List<Object?> get props => [optionName, sellingPrice, platformOptionId];
}

/// 옵션 수정. 구성품은 그대로 보존된다(읽기 전용).
class UpdateOption extends ProductListingCreateEvent {
  final num optionId;
  final String optionName;
  final int sellingPrice;
  final String? platformOptionId;

  const UpdateOption({
    required this.optionId,
    required this.optionName,
    required this.sellingPrice,
    this.platformOptionId,
  });

  @override
  List<Object?> get props =>
      [optionId, optionName, sellingPrice, platformOptionId];
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
