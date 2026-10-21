// 11st shipping settings — port of web `domain/entities/ElevenstShipping.ts` (FEATURE_2610_13 / D84 · D85 · D91 ·
// D104 · D106). One string map with `elevenst.*` keys at every level: the 11st channel default, the master override
// (shared with the Coupang keys) and an 11st listing override. Mirrors the backend `ElevenstShippingKeys`.

const String kElevenstPrefix = 'elevenst.';

/// Web `ELEVENST_KEYS`.
abstract final class ElevenstKeys {
  static const String areaCode = 'elevenst.dlvCnAreaCd';
  static const String method = 'elevenst.dlvWyCd';
  static const String courier = 'elevenst.dlvEtprsCd';
  static const String feeType = 'elevenst.dlvCstInstBasiCd';
  static const String fee = 'elevenst.dlvCst1';
  static const String freeOver = 'elevenst.prdFrDlvBasiAmt';
  static const String tierStarts = 'elevenst.dlvCnt1';
  static const String tierEnds = 'elevenst.dlvCnt2';
  static const String tierFees = 'elevenst.dlvCst3';
  static const String perItemFee = 'elevenst.dlvCst4';
  static const String payType = 'elevenst.dlvCstPayTypCd';
  static const String codNotice = 'elevenst.dlvCstInfoCd';
  static const String bundle = 'elevenst.bndlDlvCnYn';
  static const String jejuFee = 'elevenst.jejuDlvCst';
  static const String islandFee = 'elevenst.islandDlvCst';
  static const String returnFee = 'elevenst.rtngdDlvCst';
  static const String exchangeFee = 'elevenst.exchDlvCst';
  static const String returnFeeMethod = 'elevenst.rtngdDlvCd';
  static const String outboundSeq = 'elevenst.addrSeqOut';
  static const String returnSeq = 'elevenst.addrSeqIn';
}

/// Web `ELEVENST_PLACE_KEYS` — address numbers of one 11st account, never on the master (D85).
const List<String> kElevenstPlaceKeys = [
  ElevenstKeys.outboundSeq,
  ElevenstKeys.returnSeq,
];

/// D91 — web `ELEVENST_*_OPTIONS` (09 · 10 are not offered).
const List<(String, String)> kElevenstAreaOptions = [
  ('01', '전국'),
  ('02', '전국(제주·도서산간 제외)'),
];
const List<(String, String)> kElevenstMethodOptions = [
  ('01', '택배'),
  ('03', '직접전달(화물배달)'),
  ('04', '퀵서비스'),
  ('05', '배송 필요 없음'),
];
const List<(String, String)> kElevenstFeeTypeOptions = [
  ('01', '무료'),
  ('02', '고정 배송비'),
  ('03', '조건부 무료'),
  ('04', '수량별 차등'),
  ('05', '1개당 배송비'),
  ('07', '판매자 조건부 배송비(셀러오피스 설정)'),
  ('08', '출고지 조건부 배송비(셀러오피스 설정)'),
];
const List<(String, String)> kElevenstPayTypeOptions = [
  ('01', '선결제/착불 가능'),
  ('02', '착불'),
  ('03', '선결제'),
];
const List<(String, String)> kElevenstBundleOptions = [
  ('Y', '가능'),
  ('N', '불가'),
];
const List<(String, String)> kElevenstReturnFeeMethodOptions = [
  ('01', '왕복(편도×2)'),
  ('02', '편도'),
];
const List<(String, String)> kElevenstCodNoticeOptions = [
  ('01', '상품상세 참고'),
  ('02', '상품별 차등'),
  ('03', '지역별 차등'),
  ('04', '상품/지역별 차등'),
  ('06', '서울/경기 무료, 이외 추가'),
];

/// D106: at most 10 quantity tiers.
const int kElevenstMaxTiers = 10;

const String kTierLimitMessage = '수량별 배송비는 10구간까지 넣을 수 있습니다.';
const String kTierChainMessage =
    '수량별 배송비 구간이 이어지지 않습니다. 첫 구간은 1개부터, 다음 구간은 앞 구간 끝 수량 + 1 부터 시작해야 합니다.';

/// One 「04 수량별 차등」 row as typed — [end] is blank on the last row (D106).
class ElevenstTier {
  final String start;
  final String end;
  final String fee;

  const ElevenstTier(
      {required this.start, required this.end, required this.fee});

  ElevenstTier copyWith({String? start, String? end, String? fee}) =>
      ElevenstTier(
        start: start ?? this.start,
        end: end ?? this.end,
        fee: fee ?? this.fee,
      );
}

List<String> _split(String? joined) =>
    joined == null || joined.trim().isEmpty ? const [] : joined.split('^');

/// Web `tiersOf` — the stored `^`-joined strings → editable rows.
List<ElevenstTier> tiersOf(Map<String, String> map) {
  final starts = _split(map[ElevenstKeys.tierStarts]);
  final ends = _split(map[ElevenstKeys.tierEnds]);
  final fees = _split(map[ElevenstKeys.tierFees]);
  // A row lives while its start or fee is stored.
  final count = starts.length > fees.length ? starts.length : fees.length;
  return [
    for (var i = 0; i < count; i++)
      ElevenstTier(
        start: i < starts.length ? starts[i] : '',
        end: i < ends.length ? ends[i] : '',
        fee: i < fees.length ? fees[i] : '',
      ),
  ];
}

/// Web `withTiers` — editable rows → the three stored keys; no rows removes the three keys.
Map<String, String> withTiers(
    Map<String, String> map, List<ElevenstTier> tiers) {
  final next = Map<String, String>.of(map)
    ..remove(ElevenstKeys.tierStarts)
    ..remove(ElevenstKeys.tierEnds)
    ..remove(ElevenstKeys.tierFees);
  if (tiers.isEmpty) {
    return next;
  }
  next[ElevenstKeys.tierStarts] = tiers.map((t) => t.start.trim()).join('^');
  next[ElevenstKeys.tierEnds] =
      tiers.sublist(0, tiers.length - 1).map((t) => t.end.trim()).join('^');
  next[ElevenstKeys.tierFees] = tiers.map((t) => t.fee.trim()).join('^');
  return next;
}

final RegExp _count = RegExp(r'^\d+$');

/// Web `tierError` — the D106 save check, same rule and wording as the backend. null = fine.
String? tierError(Map<String, String> map) {
  final tiers = tiersOf(map);
  if (tiers.isEmpty) {
    return null;
  }
  if (tiers.length > kElevenstMaxTiers) {
    return kTierLimitMessage;
  }
  bool isCount(String v) => _count.hasMatch(v.trim());
  if (!tiers.every((t) => isCount(t.start) && isCount(t.fee))) {
    return kTierChainMessage;
  }
  if (int.parse(tiers.first.start.trim()) != 1) {
    return kTierChainMessage;
  }
  for (var i = 0; i < tiers.length - 1; i++) {
    final end = tiers[i].end.trim();
    if (!isCount(end) || int.parse(end) < int.parse(tiers[i].start.trim())) {
      return kTierChainMessage;
    }
    if (int.parse(tiers[i + 1].start.trim()) != int.parse(end) + 1) {
      return kTierChainMessage;
    }
  }
  return null;
}

/// Web `cleanElevenstMap` — blank values dropped (a blank = 「기본값 사용」 on the master / listing level).
Map<String, String> cleanElevenstMap(Map<String, String> map) => {
      for (final e in map.entries)
        if (e.key.startsWith(kElevenstPrefix) && e.value.trim().isNotEmpty)
          e.key: e.value.trim(),
    };

/// Web `pickElevenst` — the `elevenst.*` part of a stored override map (the master map holds both platforms).
Map<String, String> pickElevenst(Map<String, String>? map) => {
      for (final e in (map ?? const <String, String>{}).entries)
        if (e.key.startsWith(kElevenstPrefix)) e.key: e.value,
    };

/// Web `mergeElevenstPreset` — the listing's own value wins per key, otherwise the inherited baseline.
Map<String, String> mergeElevenstPreset(
  Map<String, String> own,
  Map<String, String> base,
) =>
    {...cleanElevenstMap(base), ...cleanElevenstMap(own)};

/// Web `diffElevenst` — only the keys changed from the baseline become the listing's override.
Map<String, String> diffElevenst(
  Map<String, String> form,
  Map<String, String> base,
) {
  final cleanBase = cleanElevenstMap(base);
  return {
    for (final e in cleanElevenstMap(form).entries)
      if (cleanBase[e.key] != e.value) e.key: e.value,
  };
}

/// Web `recalcFailureNote` (D120) — the note a shipping save adds when some
/// 11st (or, FEATURE_2610_26 / D65, ESM) listings could not be re-priced;
/// `null` when there is none.
String? recalcFailureNote(int failed) => failed > 0
    ? '가격을 다시 계산하지 못한 상품 $failed개 — [가격 점검]에서 확인하세요'
    : null;

/// Web `withRecalcNote` (D120) — [text], then one space and the note.
String withRecalcNote(String text, int failed) {
  final note = recalcFailureNote(failed);
  return note == null ? text : '$text $note';
}
