// The two 11st notice texts kept as template field values — port of web `domain/entities/ElevenstNoticeText.ts`
// (FEATURE_2610_13 / D73 · D74 · D78). Same keys as the backend `ListingTextValueResolver`.

const String kAsNoticeKey = 'asNotice';
const String kReturnExchangeNoticeKey = 'returnExchangeNotice';

/// D74: the two fields the master screens always show, in this order.
const List<(String, String)> kNoticeTextFields = [
  (kAsNoticeKey, 'A/S 안내'),
  (kReturnExchangeNoticeKey, '반품/교환 안내'),
];

const List<String> kNoticeTextKeys = [kAsNoticeKey, kReturnExchangeNoticeKey];

/// D78: 11st takes at most 4000 EUC-KR bytes per notice text.
const int kNoticeTextMaxBytes = 4000;
const String kNoticeTextTooLongMessage = '11번가는 약 2,000자까지입니다';

/// EUC-KR length: ASCII 1 byte, everything else 2 bytes (Hangul is 2 bytes in EUC-KR).
int eucKrByteLength(String text) =>
    text.runes.fold(0, (sum, rune) => sum + (rune < 0x80 ? 1 : 2));

/// D78: true when either notice text of [values] is over the 11st limit.
bool noticeTextTooLong(Map<String, String> values) => kNoticeTextKeys
    .any((key) => eucKrByteLength(values[key] ?? '') > kNoticeTextMaxBytes);
