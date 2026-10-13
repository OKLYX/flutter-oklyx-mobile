/// Screen name of a platform value. The stored / API value stays `ELEVENST`;
/// screens show 「11번가」. Other platforms are returned unchanged.
///
/// ❌ Display only — never send the returned text to the server.
/// Web twin: `nextjs-oklyx-front/src/config/platforms.ts` `platformDisplayName`.
String platformDisplayName(String platform) =>
    platform == 'ELEVENST' ? '11번가' : platform;
