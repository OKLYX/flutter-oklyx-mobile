// Category block on the master detail sales-channel rows — FEATURE_2610_11 /
// D19 · D20 · D25 — and the own platform category line of the detail category
// block (FEATURE_2610_12 / D48). Web original:
// `master-products/components/platformCategory.ts`.
// Only Coupang · 11st are blocked; Naver has no category list (D18 (d)).
// ❌ No category picker on mobile — the notice points to the web (D16).

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';

/// Platforms whose upload buttons hide when the standard category has no
/// mapping row and the master has no own platform category for them (D20 ·
/// FEATURE_2610_12 / D41).
const List<String> kCategoryBlockPlatforms = ['COUPANG', 'ELEVENST'];

/// Web `activeLookupPlatformsOf` — the [kCategoryBlockPlatforms] that have a switched-on sales channel
/// (FEATURE_2610_13 / D98: the platforms the master shipping and notice tabs show).
List<String> activeLookupPlatformsOf(List<AccountPlatform> accounts) => [
      for (final p in kCategoryBlockPlatforms)
        if (accounts.any((a) => a.isActive && a.platform == p)) p,
    ];

/// Screen label of a [kCategoryBlockPlatforms] platform (「쿠팡」 · 「11번가」) — the category
/// block notices and the master shipping tabs (FEATURE_2610_13 / D98).
String categoryPlatformLabel(String platform) =>
    platform == 'COUPANG' ? platformName('COUPANG') : platformName('ELEVENST');

/// Notice shown where the upload buttons are hidden (D18 (h) + D25).
String categoryBlockText(String platform) {
  final label = categoryPlatformLabel(platform);
  return '카테고리 연결 필요 — 이 기준 카테고리에 $label 카테고리가 없어 '
      '올릴 수 없습니다. 카테고리는 웹에서 고를 수 있습니다.';
}

/// FEATURE_2610_12 / D48 · D50: the master's own platform category line on the
/// detail category block — 「{플랫폼}: {경로} (개별 지정)」. Path = the cached
/// display path, or the code when no path was cached.
String ownPlatformCategoryText(CategoryMapping own) {
  final path = own.platformCategoryName;
  return '${categoryPlatformLabel(own.platform)}: '
      '${path == null || path.isEmpty ? own.platformCategoryId : path} (개별 지정)';
}
