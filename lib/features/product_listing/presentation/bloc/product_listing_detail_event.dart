abstract class ProductListingDetailEvent {}

/// 판매상품 상세 + 옵션 로드
class LoadProductListingDetail extends ProductListingDetailEvent {
  final int id;

  LoadProductListingDetail(this.id);
}
