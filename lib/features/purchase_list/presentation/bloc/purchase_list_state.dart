import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/purchase_list_item.dart';

abstract class PurchaseListState {}

/// 초기 상태 (진입 직후)
class PurchaseListInitial extends PurchaseListState {}

/// 최초 로드 중 (전체 화면 스피너)
class PurchaseListLoading extends PurchaseListState {}

/// 최초 로드 실패 (전체 화면 + 재시도)
class PurchaseListError extends PurchaseListState {
  final String message;

  PurchaseListError({required this.message});
}

/// 조회 성공 상태.
///
/// 판매자 드롭다운/재적재/펼침 컨트롤을 유지해야 하므로, 재조회·재적재·라인
/// 액션 진행은 별도 상태가 아닌 플래그([isRefreshing]/[isExtracting])로 표현한다
/// (프론트 OrderContainer/PurchaseListContainer와 동일). 일시적 실패는
/// [actionError]로 전달해 SnackBar로 표시한 뒤 다음 상태에서 비운다.
class PurchaseListLoaded extends PurchaseListState {
  final List<Seller> sellers;
  final int? selectedSellerId;
  final List<PurchaseListItem> items;

  /// 현재 펼쳐진 상품 productId (null = 모두 접힘)
  final int? expandedProductId;

  final bool isRefreshing;
  final bool isExtracting;
  final String? actionError;

  PurchaseListLoaded({
    required this.sellers,
    this.selectedSellerId,
    required this.items,
    this.expandedProductId,
    this.isRefreshing = false,
    this.isExtracting = false,
    this.actionError,
  });

  PurchaseListLoaded copyWith({
    List<Seller>? sellers,
    int? selectedSellerId,
    bool clearSelectedSeller = false,
    List<PurchaseListItem>? items,
    int? expandedProductId,
    bool clearExpanded = false,
    bool? isRefreshing,
    bool? isExtracting,
    String? actionError,
    bool clearActionError = false,
  }) {
    return PurchaseListLoaded(
      sellers: sellers ?? this.sellers,
      selectedSellerId: clearSelectedSeller
          ? null
          : (selectedSellerId ?? this.selectedSellerId),
      items: items ?? this.items,
      expandedProductId: clearExpanded
          ? null
          : (expandedProductId ?? this.expandedProductId),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isExtracting: isExtracting ?? this.isExtracting,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}
