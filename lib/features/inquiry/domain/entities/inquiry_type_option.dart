import 'inquiry.dart';

/// 플랫폼이 지원하는 문의 유형 1개 — `GET /api/inquiries/types` (PLAN M2).
///
/// **용도**: 목록 화면 유형 탭의 **유일한** 원천. 코드도 라벨도 서버가 준다.
/// **파일**: lib/features/inquiry/domain/entities/inquiry_type_option.dart
///
/// ❌ 앱에 `PRODUCT_QNA: '상품문의'` 같은 표를 만들지 말 것 — 네이버가 붙는 날
/// 웹·앱 두 곳을 고쳐야 한다.
class InquiryTypeOption {
  /// 서버가 준 유형 코드를 파싱한 값. 조회 파라미터로는 `code.wire` 를 보낸다.
  final InquiryType code;

  /// 사용자 노출 문구 — **서버가 정한다**.
  final String label;

  const InquiryTypeOption({required this.code, required this.label});
}

/// `GET /api/inquiries/types` 응답 1건(플랫폼 + 그 플랫폼의 유형 목록).
///
/// 화면은 플랫폼별로 탭을 나누지 않는다 — 응답을 평탄화해 유형 탭 하나로 쓴다
/// (웹 `InquiryUseCase.flattenTypes` 와 같은 처리).
class PlatformInquiryTypes {
  final String platform;
  final List<InquiryTypeOption> types;

  const PlatformInquiryTypes({required this.platform, required this.types});
}

/// 플랫폼별 목록 → 유형 탭 후보. 같은 코드는 **처음 것만** 남긴다(플랫폼이 늘어도 탭은
/// 유형 축 하나다).
List<InquiryTypeOption> flattenInquiryTypes(
  List<PlatformInquiryTypes> platforms,
) {
  final seen = <InquiryType>{};
  final options = <InquiryTypeOption>[];
  for (final platform in platforms) {
    for (final option in platform.types) {
      if (seen.add(option.code)) options.add(option);
    }
  }
  return options;
}
