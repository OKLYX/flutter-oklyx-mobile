/// 개수 단위 고정 목록 (FEATURE_2609_76 / D12) — 순서가 곧 드롭다운 순서다.
///
/// 🔴 백엔드 `ProductServiceImpl.VALID_COUNT_UNITS` · 웹 `COUNT_UNITS` 와 글자·순서까지 같다.
/// ❌ 무게·부피 단위 `Unit` enum(KG·G·L·ML)과 섞지 않는다(D7).
const List<String> kCountUnits = ['개', '장', '매', '봉', '팩', '롤', '입'];

/// 물품 계량 입력 검사 (FEATURE_2609_76 / D6 · D12 · D18) — 첫 번째 위반 문구, 없으면 null.
///
/// 🔴 문구는 웹 폼 검사 문구와 글자까지 같다. 서버도 같은 규칙으로 400 을 낸다 — 이 검사는 먼저 알려 줄 뿐이다.
/// **쓰는 곳**: `ProductRegisterPage._onSubmit` · `ProductDetailPage._onSave`.
String? productMeasureInputError({
  required String netContent,
  required bool hasNetContentUnit,
  required String countQuantity,
  required String? countUnit,
}) {
  final hasContent = netContent.trim().isNotEmpty;
  if (hasContent && !hasNetContentUnit) return '내용물 양을 입력하면 단위를 함께 선택해주세요';
  if (!hasContent && hasNetContentUnit) return '단위를 고르면 내용물 양을 함께 입력해주세요';
  final quantity = countQuantity.trim();
  if (quantity.isNotEmpty && !RegExp(r'^[1-9][0-9]*$').hasMatch(quantity)) {
    return '개수는 1 이상의 정수로 입력해주세요';
  }
  if (quantity.isNotEmpty && countUnit == null) return '개수를 입력하면 개수 단위를 함께 선택해주세요';
  if (quantity.isEmpty && countUnit != null) return '개수 단위를 고르면 개수를 함께 입력해주세요';
  return null;
}
