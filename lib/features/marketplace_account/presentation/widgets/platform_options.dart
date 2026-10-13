/// 판매채널 플랫폼 옵션 (프론트엔드 ChannelRegistrationForm 의 PLATFORM_OPTIONS 와 동일).
///
/// 현재는 하드코딩이며, 추후 관리되는 플랫폼 목록으로 대체될 예정이다.
class PlatformOption {
  final String value;
  final String label;

  const PlatformOption(this.value, this.label);
}

const List<PlatformOption> kPlatformOptions = [
  PlatformOption('COUPANG', '쿠팡'),
  PlatformOption('NAVER', '네이버 스마트스토어'),
  PlatformOption('ELEVENST', '11번가'),
  PlatformOption('GMARKET', 'G마켓'),
];

/// 플랫폼 코드를 표시용 한글 라벨로 변환. 알 수 없는 코드는 원본을 반환.
String platformLabel(String platform) {
  for (final option in kPlatformOptions) {
    if (option.value == platform) return option.label;
  }
  return platform;
}
