// Gmarket · Auction (ESM) shipping settings — port of web
// `domain/entities/EsmShipping.ts` (FEATURE_2610_26 / D36 · D37 · D60 · D66).
// One string map of `esm.*` keys at both levels: the ESM channel layer (its
// own table) and an ESM listing override. There is no master level. Mirrors
// the backend `EsmShippingKeys`.

const String kEsmPrefix = 'esm.';

/// Web `ESM_KEYS` — D36: the six values a person picks or types.
abstract final class EsmKeys {
  static const String placeNo = 'esm.placeNo';
  static const String bundlePolicyNo = 'esm.bundlePolicyNo';
  static const String dispatchPolicyNo = 'esm.dispatchPolicyNo';
  static const String returnAddrNo = 'esm.returnAddrNo';
  static const String companyNo = 'esm.companyNo';
  static const String returnFee = 'esm.returnFee';
}

/// Web `ESM_INPUT_KEYS` — the six input keys in screen order.
const List<String> kEsmInputKeys = [
  EsmKeys.placeNo,
  EsmKeys.bundlePolicyNo,
  EsmKeys.dispatchPolicyNo,
  EsmKeys.returnAddrNo,
  EsmKeys.companyNo,
  EsmKeys.returnFee,
];

/// Web `ESM_LABELS` — D36: the screen labels of the six values.
const Map<String, String> kEsmLabels = {
  EsmKeys.placeNo: '출하지',
  EsmKeys.bundlePolicyNo: '묶음배송비',
  EsmKeys.dispatchPolicyNo: '발송정책',
  EsmKeys.returnAddrNo: '반품/교환지',
  EsmKeys.companyNo: '택배사',
  EsmKeys.returnFee: '반품 배송비(편도)',
};

/// Web `ESM_PAIR_MESSAGE` — D66 (listing level): the place and the
/// bundle-fee policy are set together or left together.
const String kEsmPairMessage = '출하지와 묶음배송비는 함께 고르세요';

/// Web `cleanEsmMap` — the six input keys with a non-blank value, trimmed.
/// The server writes the policy keys itself (D66).
Map<String, String> cleanEsmMap(Map<String, String>? map) => {
      for (final key in kEsmInputKeys)
        if ((map?[key] ?? '').trim().isNotEmpty) key: map![key]!.trim(),
    };

/// Web `esmShippingUnset` — D36: true while one of the six input keys is
/// still empty (= shipping not set).
bool esmShippingUnset(Map<String, String>? map) {
  final clean = cleanEsmMap(map);
  return kEsmInputKeys.any((key) => clean[key] == null);
}

/// Web `mergeEsmPreset` — the listing's own value wins per key, otherwise
/// the channel layer.
Map<String, String> mergeEsmPreset(
  Map<String, String> own,
  Map<String, String> base,
) =>
    {...cleanEsmMap(base), ...cleanEsmMap(own)};

/// Web `diffEsm` — the listing override to save: the keys that differ from
/// the channel layer; the place and the bundle-fee policy go together when
/// either differs (D66).
Map<String, String> diffEsm(
  Map<String, String> form,
  Map<String, String> base,
) {
  final cleanForm = cleanEsmMap(form);
  final cleanBase = cleanEsmMap(base);
  final out = <String, String>{
    for (final e in cleanForm.entries)
      if (cleanBase[e.key] != e.value) e.key: e.value,
  };
  final pairChanged = out[EsmKeys.placeNo] != null ||
      out[EsmKeys.bundlePolicyNo] != null;
  if (pairChanged) {
    final place = cleanForm[EsmKeys.placeNo];
    final bundle = cleanForm[EsmKeys.bundlePolicyNo];
    if (place != null) {
      out[EsmKeys.placeNo] = place;
    }
    if (bundle != null) {
      out[EsmKeys.bundlePolicyNo] = bundle;
    }
  }
  return out;
}

/// Web `esmPairError` — D66 save check of a listing override: null = fine.
String? esmPairError(Map<String, String> override) {
  final place = override[EsmKeys.placeNo] != null;
  final bundle = override[EsmKeys.bundlePolicyNo] != null;
  return place == bundle ? null : kEsmPairMessage;
}
