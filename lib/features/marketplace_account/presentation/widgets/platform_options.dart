import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';

/// One option of the sales-channel platform select. The values and names
/// come from `lib/core/utils/platform_display.dart` (FEATURE_2610_22 / D15;
/// web twin `ChannelRegistrationForm` `PLATFORM_OPTIONS`).
class PlatformOption {
  final String value;
  final String label;

  const PlatformOption(this.value, this.label);
}

final List<PlatformOption> kPlatformOptions = [
  for (final p in kPlatforms) PlatformOption(p, platformName(p)),
];

/// 플랫폼 코드를 표시용 한글 라벨로 변환. 알 수 없는 코드는 원본을 반환.
String platformLabel(String platform) => platformName(platform);
