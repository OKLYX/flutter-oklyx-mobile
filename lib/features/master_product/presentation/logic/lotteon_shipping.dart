// LotteON shipping settings — port of web
// `domain/entities/LotteonShipping.ts` (FEATURE_2610_24 / D42 · D43 · D65).
// One string map of `lotteon.*` keys at both levels: the LotteON channel
// layer (its own table) and a LotteON listing override. There is no master
// level. Mirrors the backend `LotteonShippingKeys`.
//
// ❌ The policy fee keys (`lotteon.dvCstDvsCd` · `lotteon.dvCst` ·
// `lotteon.cndlFreeStdAmt`) are written by the server (D65) — screens never
// send them.

const String kLotteonPrefix = 'lotteon.';

/// Web `LOTTEON_KEYS` — D42: the three numbers a person picks.
abstract final class LotteonKeys {
  static const String owhpNo = 'lotteon.owhpNo';
  static const String rtrpNo = 'lotteon.rtrpNo';
  static const String dvCstPolNo = 'lotteon.dvCstPolNo';
}

/// Web `LOTTEON_INPUT_KEYS` — the three input keys in screen order.
const List<String> kLotteonInputKeys = [
  LotteonKeys.owhpNo,
  LotteonKeys.rtrpNo,
  LotteonKeys.dvCstPolNo,
];

/// Web `LOTTEON_LABELS` — D42: the screen labels of the three numbers.
const Map<String, String> kLotteonLabels = {
  LotteonKeys.owhpNo: '출고지',
  LotteonKeys.rtrpNo: '회수지',
  LotteonKeys.dvCstPolNo: '배송비 정책',
};

/// Web `cleanLotteonMap` — the three input keys with a non-blank value,
/// trimmed. The server writes the policy fee keys itself (D65).
Map<String, String> cleanLotteonMap(Map<String, String>? map) => {
      for (final key in kLotteonInputKeys)
        if ((map?[key] ?? '').trim().isNotEmpty) key: map![key]!.trim(),
    };

/// Web `lotteonShippingUnset` — D42: true while one of the three input keys
/// is still empty (= shipping not set).
bool lotteonShippingUnset(Map<String, String>? map) {
  final clean = cleanLotteonMap(map);
  return kLotteonInputKeys.any((key) => clean[key] == null);
}

/// Web `mergeLotteonPreset` — the listing's own value wins per key,
/// otherwise the channel layer.
Map<String, String> mergeLotteonPreset(
  Map<String, String> own,
  Map<String, String> base,
) =>
    {...cleanLotteonMap(base), ...cleanLotteonMap(own)};

/// Web `diffLotteon` — the listing override to save: the input keys that
/// differ from the channel layer.
Map<String, String> diffLotteon(
  Map<String, String> form,
  Map<String, String> base,
) {
  final cleanForm = cleanLotteonMap(form);
  final cleanBase = cleanLotteonMap(base);
  return {
    for (final e in cleanForm.entries)
      if (cleanBase[e.key] != e.value) e.key: e.value,
  };
}
