import '../../domain/entities/inquiry.dart';
import '../../domain/entities/inquiry_type_option.dart';

/// `GET /api/inquiries/types` 응답 1건 → [PlatformInquiryTypes].
///
/// ⚠️ 라벨은 서버가 준 `label` 을 그대로 쓴다(PLAN M2) — 코드→라벨 표를 앱에 만들지 말 것.
class PlatformInquiryTypesModel extends PlatformInquiryTypes {
  const PlatformInquiryTypesModel({
    required super.platform,
    required super.types,
  });

  factory PlatformInquiryTypesModel.fromJson(Map<String, dynamic> json) =>
      PlatformInquiryTypesModel(
        platform: json['platform'] as String? ?? '',
        types: _parseTypes(json['types']),
      );

  static List<InquiryTypeOption> _parseTypes(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => InquiryTypeOption(
            code: parseInquiryType(e['code'] as String?),
            // 라벨이 비면 최소한 코드라도 보이게 한다(빈 탭보다 낫다).
            label: (e['label'] as String?)?.trim().isNotEmpty == true
                ? e['label'] as String
                : parseInquiryType(e['code'] as String?).wire,
          ),
        )
        .toList();
  }
}
