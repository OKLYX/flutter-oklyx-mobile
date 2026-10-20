/// Screen name of a platform value. The stored / API value stays `ELEVENST`;
/// screens show 「11번가」. Other platforms are returned unchanged.
///
/// ❌ Display only — never send the returned text to the server.
/// Web twin: `nextjs-oklyx-front/src/config/platforms.ts` `platformDisplayName`.
String platformDisplayName(String platform) =>
    platform == 'ELEVENST' ? '11번가' : platform;

/// Marketplace platforms the server accepts (FEATURE_2610_22 / D10 · D15).
/// The platform selects of the sales-channel form, the commission rate forms,
/// the sales-product register page and the sales-product search filter are
/// built from this list. A new marketplace adds its value here in its
/// sales-channel work (D10).
/// Web twin: `nextjs-oklyx-front/src/config/platforms.ts` `PLATFORMS`.
const List<String> kPlatforms = ['COUPANG', 'ELEVENST'];

const Map<String, String> _platformNames = {
  'COUPANG': '쿠팡',
  'NAVER': '네이버',
  'ELEVENST': '11번가',
};

/// Screen name of a platform value (FEATURE_2610_22 / D15 · D18): 「쿠팡」 ·
/// 「네이버」 · 「11번가」. A value missing from the table is returned
/// unchanged. The marketplace name tables and the platform select labels use
/// this.
///
/// ❌ Display only — do not send the returned text to the server.
/// ❌ [platformDisplayName] does not call this — its callers keep their text.
/// Web twin: `nextjs-oklyx-front/src/config/platforms.ts` `platformName`.
String platformName(String platform) => _platformNames[platform] ?? platform;
