import 'package:flutter/foundation.dart';

/// 판매상품 목록 갱신 신호.
///
/// 수정/삭제 성공 시 [notifyProductListingChanged]를 호출하면 값이 1 증가하고,
/// 조회 페이지(`ProductListingSearchPage`)가 이를 구독해 마지막 검색을 재실행한다.
///
/// **왜 필요한가:** 조회 페이지는 상세/수정 페이지가 위에 push 되는 동안에도 스택에
/// 그대로 살아있어(BLoC 유지) 돌아왔을 때 이전 결과를 그대로 보여준다. 수정/삭제
/// 결과를 반영하려면 명시적 갱신이 필요하다. (프론트의 sessionStorage
/// `refresh-product-listing` 플래그와 동일한 역할.)
///
/// `ProductListingListBloc`은 factory 라 화면마다 다른 인스턴스이고 상세/수정
/// 페이지에서 직접 접근할 수 없으므로, 페이지 간 단순 신호로 ValueNotifier 를 쓴다.
final ValueNotifier<int> productListingRefreshSignal = ValueNotifier<int>(0);

/// 판매상품이 변경(수정/삭제)되었음을 조회 페이지에 알린다.
void notifyProductListingChanged() => productListingRefreshSignal.value++;
