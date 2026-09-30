import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

/// Starting marketplace product when the create page opens in "new master"
/// mode (market entry "새 마스터로", 2609_79 / UX D70 · D71 · D77) — port of
/// web `master-products/new/components/marketSource.ts` (@09208a0).
///
/// **File**: lib/features/master_product/presentation/logic/market_source.dart
///
/// Built only when seller id, platform and platform product id are all set.
/// [preview] = the `from-channel/preview` response (never cached — price and
/// stock change).
class MarketSource {
  final int sellerId;
  final String platform;
  final String platformProductId;
  final MasterFromChannelPreview preview;

  const MarketSource({
    required this.sellerId,
    required this.platform,
    required this.platformProductId,
    required this.preview,
  });
}

/// Platform code → display name. A new platform adds one line here (UX D64).
const Map<String, String> kPlatformLabel = {'COUPANG': '쿠팡'};

/// Confirm message when components or the category change in market mode —
/// options stay, only the per-option quantities are cleared (UX D71 · D32).
const String kMarketOptionResetMessage =
    '구성상품이나 카테고리를 바꾸면 옵션별 구성 수량이 지워집니다(옵션은 마켓 상품 그대로 남습니다). 계속하시겠습니까?';

/// Head of the detail banner when attaching the listing failed after the
/// master was saved (UX D70). The server reason follows.
const String kMarketAttachFailPrefix = '마스터는 만들어졌습니다. 마켓 상품을 붙이지 못했습니다: ';

/// Appended to an existing banner when the save stopped before attaching the
/// listing (UX D70 — the user attaches it from the detail page).
const String kMarketNotAttachedSuffix =
    ' 마켓 상품은 붙이지 않았습니다 — 판매채널 줄의 [마켓 상품 추가하기]로 붙이세요.';

/// Market options → initial create-form options (UX D71). Name = market
/// option name, quantities left empty (entered by the user). Per-option
/// attributes become that option's attribute override (UX D77). Stock is not
/// set (2609_45 D3-1).
List<MasterOptionRequest> marketOptionsOf(MasterFromChannelPreview p) => [
      for (final o in p.options)
        MasterOptionRequest(
          name: o.itemName,
          items: const [],
          categoryAttributes:
              o.attributes.isNotEmpty ? {...o.attributes} : null,
        ),
    ];

/// Saved master options → option rows of the attach request (UX D70). Each
/// market option sends the quantities of the master option **with the same
/// name** — the server links quantity + name first (`resolveMasterOption`,
/// UX D80), so two options with equal quantities still land on their own
/// master option.
List<ImportOptionSpec> importOptionsOf(
  MasterFromChannelPreview p,
  List<MasterOptionRequest> options,
) =>
    [
      for (final o in p.options)
        ImportOptionSpec(
          vendorItemId: o.platformOptionId,
          itemName: o.itemName,
          masterOptionName: o.itemName,
          components: [
            for (final i in _itemsNamed(options, o.itemName))
              MasterItemQuantity(productId: i.productId, quantity: i.quantity),
          ],
        ),
    ];

// Web `options.find((opt) => opt.name === name)?.items ?? []`.
List<MasterOptionRequestItem> _itemsNamed(
  List<MasterOptionRequest> options,
  String name,
) {
  for (final opt in options) {
    if (opt.name == name) {
      return opt.items;
    }
  }
  return const [];
}
