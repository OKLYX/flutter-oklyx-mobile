/// 실물 재고 원장 enum + 라벨 (PLAN 2609_28 D6·D7).
///
/// **용도**: 이동 유형·사유의 서버 코드(`STOCK_IN`, `PURCHASE` …)와 화면 문구를 한 곳에서 잇는다.
/// **필수 규칙**: 재고 화면은 라벨을 직접 쓰지 않고 반드시 이 파일의 맵을 쓴다 —
/// 화면마다 문구를 복제하면 웹(06)과 갈라지고, 유형별 허용 사유가 어긋나면 서버가 400 을 낸다.
/// **파일**: lib/features/stock_ledger/domain/entities/stock_enums.dart
///
/// ⚠️ 값 이름은 서버 enum 과 **철자까지 같아야 한다** — JSON 직렬화가 이름 그대로다.
/// ❌ 화면에서 부호를 뒤집지 않는다. 폐기 수량은 양수로 보내고 서버가 음수로 저장한다.
library;

/// 이동 유형 (서버 `StockMovementType`).
enum StockMovementType {
  /// 입고 확인 — 주문과 무관하다(D6).
  stockIn,

  /// 출고 확인 — 주문 라인에서만 만들어진다(출고 확인 화면).
  stockOut,

  /// 반품 물품 확인 — 반품 건(orderClaimId) 필수.
  returnIn,

  /// 폐기·파손·증정 — 판매가 아닌 감소 전부.
  disposal,

  /// 실사 차이 — 수량 부호를 사용자가 정한다.
  adjust;

  /// 서버로 보내는 코드.
  String get code => switch (this) {
        StockMovementType.stockIn => 'STOCK_IN',
        StockMovementType.stockOut => 'STOCK_OUT',
        StockMovementType.returnIn => 'RETURN_IN',
        StockMovementType.disposal => 'DISPOSAL',
        StockMovementType.adjust => 'ADJUST',
      };

  /// 화면 문구 (웹 06 과 동일).
  String get label => switch (this) {
        StockMovementType.stockIn => '입고',
        StockMovementType.stockOut => '출고',
        StockMovementType.returnIn => '반품입고',
        StockMovementType.disposal => '폐기',
        StockMovementType.adjust => '조정',
      };

  /// 서버 코드 → enum. 모르는 값은 null (조용히 다른 유형으로 바꾸지 않는다).
  static StockMovementType? fromCode(String? code) {
    for (final type in StockMovementType.values) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// 입고·조정 화면이 만들 수 있는 유형 — 출고는 주문에서만 출발한다(D11).
  static const List<StockMovementType> entryTypes = [
    StockMovementType.stockIn,
    StockMovementType.returnIn,
    StockMovementType.disposal,
    StockMovementType.adjust,
  ];
}

/// 이동 사유 (서버 `StockReason`).
enum StockReason {
  purchase,
  opening,
  free,
  damaged,
  expired,
  lost,
  sample,
  internalUse,
  countDiff,
  etc;

  String get code => switch (this) {
        StockReason.purchase => 'PURCHASE',
        StockReason.opening => 'OPENING',
        StockReason.free => 'FREE',
        StockReason.damaged => 'DAMAGED',
        StockReason.expired => 'EXPIRED',
        StockReason.lost => 'LOST',
        StockReason.sample => 'SAMPLE',
        StockReason.internalUse => 'INTERNAL_USE',
        StockReason.countDiff => 'COUNT_DIFF',
        StockReason.etc => 'ETC',
      };

  String get label => switch (this) {
        StockReason.purchase => '매입',
        StockReason.opening => '기초재고',
        StockReason.free => '무상·보상',
        StockReason.damaged => '파손',
        StockReason.expired => '유통기한 초과',
        StockReason.lost => '분실',
        StockReason.sample => '증정·샘플',
        StockReason.internalUse => '자가소비',
        StockReason.countDiff => '실사 차이',
        StockReason.etc => '기타',
      };

  static StockReason? fromCode(String? code) {
    for (final reason in StockReason.values) {
      if (reason.code == code) return reason;
    }
    return null;
  }

  /// 유형별 허용 사유 (서버 `StockReason.allowedFor` 와 같은 표).
  ///
  /// ⚠️ `RETURN_IN` 은 사유를 받지 않는다 — 빈 목록이면 화면이 사유 칸을 비활성화한다.
  static List<StockReason> forType(StockMovementType type) => switch (type) {
        StockMovementType.stockIn => const [
            StockReason.purchase,
            StockReason.opening,
            StockReason.free,
            StockReason.etc,
          ],
        StockMovementType.disposal => const [
            StockReason.damaged,
            StockReason.expired,
            StockReason.lost,
            StockReason.sample,
            StockReason.internalUse,
            StockReason.etc,
          ],
        StockMovementType.adjust => const [
            StockReason.countDiff,
            StockReason.etc,
          ],
        StockMovementType.returnIn => const [],
        StockMovementType.stockOut => const [],
      };
}

/// 전개 실패 사유 코드 → 문구. 모르는 코드는 원문을 그대로 보여준다(숨기지 않는다).
String unexpandedReasonLabel(String reason) => switch (reason) {
      'UNMAPPED_OPTION' => '판매 옵션 미연결',
      'NO_MASTER_OPTION' => '마스터 옵션 미연결',
      'EMPTY_BOM' => '구성 물품 없음',
      _ => reason,
    };
