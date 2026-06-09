abstract class ProductListingDetailEvent {}

/// 판매상품 상세 + 옵션 로드
class LoadProductListingDetail extends ProductListingDetailEvent {
  final int id;

  LoadProductListingDetail(this.id);
}

/// 판매상품 삭제 (프론트 상세 페이지 삭제 버튼 → 확인 다이얼로그 → delete API와 동일)
class DeleteProductListing extends ProductListingDetailEvent {
  final int id;

  DeleteProductListing(this.id);
}
