import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/cell_actions.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/copy_id_button.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/listing_detail_panel.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_network_image.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/info_bubble_icon.dart';

/// Status enum → screen text. ⚠️ Never show the raw enum (`SELLING` …).
const Map<String, String> kListingStatusLabel = {
  'DRAFT': '미전송',
  'SUBMITTED': '승인 대기중',
  'SELLING': '판매중',
  'REJECTED': '승인 반려',
  'SUSPENDED': '판매 중지',
};

/// 「카테고리 불일치」 chip hint (2609_45/D8).
const String _ownCategoryHint =
    '이 채널은 마켓에 올라가 있는 자기 카테고리를 사용합니다(마스터 카테고리와 다름). 수수료·필수 항목도 이 카테고리 기준입니다. ⋯ 메뉴의 [마스터 카테고리로 변경]으로 맞출 수 있습니다.';

const String _needsSyncHint =
    '이 채널에서 바꾼 값이 아직 마켓에 가지 않았습니다. [수정 요청]으로 보냅니다.';

/// A cell's registration status. **The backend value wins**; the old guess is
/// only a fallback for legacy responses.
String cellStatus(MatrixCell? cell) {
  final status = cell?.status;
  if (status != null) {
    return status;
  }
  final pid = cell?.platformProductId;
  return pid != null && pid.isNotEmpty
      ? ListingStatusCode.submitted
      : ListingStatusCode.draft;
}

/// "Action needed" chips of this listing = unsynced changes + category
/// mismatch. The account header sums them.
/// ⚠️ Both read the server value only (`== true`).
int cellActionCount(MatrixCell cell) =>
    (cell.needsMarketSync == true ? 1 : 0) +
    (cell.usesOwnCategory == true ? 1 : 0);

/// One option card line = `optionPrices` (active · lock · price · stock),
/// overlaid with `channel-options` (option ID · master link) by option id.
/// ⚠️ `optionPrices` wins for the active flag.
List<ListingOptionView> _buildOptionViews(
  GeneratedProduct? gen,
  List<ListingOptionSummary>? channelOptions,
  List<MasterOption> masterOptions,
) {
  final prices = gen?.optionPrices ?? const <OptionPrice>[];
  final byId = {
    for (final o in channelOptions ?? const <ListingOptionSummary>[])
      o.optionId: o,
  };
  if (prices.isNotEmpty) {
    return prices.map((p) {
      final co = byId[p.optionId];
      final active = p.active != false;
      final master = masterOptions.where((o) => o.id == p.optionId);
      return ListingOptionView(
        optionId: p.optionId,
        name: p.optionName ??
            co?.optionName ??
            (master.isNotEmpty ? master.first.name : '옵션 #${p.optionId}'),
        sellingPrice: p.sellingPrice,
        priceManual: p.priceSource == GeneratedSourceCode.manualOverride,
        stock: p.stockQuantity ?? p.maxStock,
        stockInherited: p.stockQuantity == null,
        active: active,
        lockedOff: p.onMarket == true && active,
        platformOptionId: co?.platformOptionId,
        masterOptionId: co?.masterOptionId,
        masterOptionKnown: co != null,
      );
    }).toList();
  }
  // No generated product (yet): draw from the channel options only (no lock).
  return (channelOptions ?? const <ListingOptionSummary>[])
      .map(
        (o) => ListingOptionView(
          optionId: o.optionId,
          name: o.optionName,
          sellingPrice: o.sellingPrice,
          priceManual: o.priceSource == GeneratedSourceCode.manualOverride,
          stock: o.stockQuantity ?? o.maxStock,
          stockInherited: o.stockQuantity == null,
          active: o.active,
          lockedOff: false,
          platformOptionId: o.platformOptionId,
          masterOptionId: o.masterOptionId,
          masterOptionKnown: true,
        ),
      )
      .toList();
}

/// One listing (cell) line of the channel matrix — **collapsed by default** —
/// FEATURE_2609_80 / 08.
///
/// **File**: lib/features/master_product/presentation/widgets/listing_row.dart
/// **Web original**: `master-products/[id]/components/ListingRow.tsx` @09208a0
///
/// Collapsed = expand arrow · small thumbnail · display name · sub line
/// (product ID · option count · lowest price~ · stock total) · status chip
/// (+ 「변경 미반영」 · 「카테고리 불일치」) · actions ([CellActions]).
/// Expanded = [ListingDetailPanel] below the line.
///
/// [genLoaded] = web `gen !== undefined` (lookup finished; failure =
/// `gen == null && genLoaded`).
///
/// ⚠️ The expanded state is local — render with `key: ValueKey(listingId)` so
///    a reload keeps it.
/// ❌ No web view per row (R13) — the 「상세」 box opens the preview sheet.
class ListingRow extends StatefulWidget {
  final int masterId;
  final MatrixCell cell;
  final GeneratedProduct? gen;
  final bool genLoaded;
  final bool genLoading;

  /// This cell's channel options. `null` = not loaded.
  final List<ListingOptionSummary>? channelOptions;
  final bool channelOptionsLoading;
  final List<MasterOption> masterOptions;

  /// Title tag for windows (`판매자 · 플랫폼[ · 상품ID]`).
  final String channelLabel;
  final int accountId;
  final String platform;
  final ValueChanged<int> onEditMasterOption;
  final VoidCallback onReload;
  final void Function(GeneratedProduct? gen, String title, String tab)
      onPreview;
  final void Function(int listingId, GeneratedProduct updated) onShippingSaved;
  final String? masterCategoryName;
  final ValueChanged<String> onCellRemoved;

  const ListingRow({
    required this.masterId,
    required this.cell,
    required this.gen,
    required this.genLoaded,
    required this.genLoading,
    required this.channelOptions,
    required this.channelOptionsLoading,
    required this.masterOptions,
    required this.channelLabel,
    required this.accountId,
    required this.platform,
    required this.onEditMasterOption,
    required this.onReload,
    required this.onPreview,
    required this.onShippingSaved,
    required this.masterCategoryName,
    required this.onCellRemoved,
    super.key,
  });

  @override
  State<ListingRow> createState() => _ListingRowState();
}

class _ListingRowState extends State<ListingRow> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cell = widget.cell;
    final gen = widget.gen;
    final status = cellStatus(cell);
    final listingId = cell.productListingId;
    final views =
        _buildOptionViews(gen, widget.channelOptions, widget.masterOptions);
    final activeViews = views.where((v) => v.active).toList();
    final prices = activeViews.map((v) => v.sellingPrice).toList();
    final minPrice =
        prices.isNotEmpty ? prices.reduce(math.min) : cell.sellingPrice;
    final hasPriceRange = prices.length > 1 && prices.toSet().length > 1;
    final stockTotal = activeViews.fold<int>(0, (sum, v) => sum + v.stock);
    final needsSync = cell.needsMarketSync == true;
    final categoryMismatch = cell.usesOwnCategory == true;
    final categoryLabel = cell.categoryName ?? cell.categoryCode;
    final thumbUrl = gen?.thumbnailUrl;
    final hasThumb = thumbUrl != null && thumbUrl.isNotEmpty;
    final pending = !widget.genLoaded && widget.genLoading;
    final pid = cell.platformProductId;
    final subStyle = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);

    final Widget smallThumb;
    if (pending) {
      smallThumb = Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (hasThumb) {
      smallThumb = GestureDetector(
        onTap: () => widget.onPreview(gen, widget.channelLabel, 'image'),
        child: MasterNetworkImage(url: thumbUrl, width: 40, height: 40),
      );
    } else {
      smallThumb = Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '–',
          style: TextStyle(fontSize: 12, color: scheme.outlineVariant),
        ),
      );
    }

    const spinner = SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    final emptyStyle = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);

    final bigThumb = pending
        ? spinner
        : hasThumb
            ? GestureDetector(
                onTap: () =>
                    widget.onPreview(gen, widget.channelLabel, 'image'),
                child: MasterNetworkImage(url: thumbUrl, width: 96, height: 96),
              )
            : Text('없음', style: emptyStyle);

    final detailHtml = gen?.detailHtml;
    // R13: a bordered 96×96 box instead of a mini web view.
    final detailThumb = pending
        ? spinner
        : detailHtml != null && detailHtml.isNotEmpty
            ? SizedBox(
                width: 96,
                height: 96,
                child: OutlinedButton(
                  onPressed: () =>
                      widget.onPreview(gen, widget.channelLabel, 'detail'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article_outlined),
                      SizedBox(height: 4),
                      Text('상세', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              )
            : Text('미생성', style: emptyStyle);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        onPressed: _toggle,
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        tooltip: _expanded ? '접기' : '펼치기',
                        icon: Icon(
                          _expanded ? Icons.expand_more : Icons.chevron_right,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    smallThumb,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _toggle,
                            child: Text(
                              cell.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (pid != null && pid.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pid,
                                      style: subStyle.copyWith(
                                        fontFamily: 'monospace',
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    CopyIdButton(value: pid),
                                  ],
                                )
                              else
                                // A draft has no market ID yet — not an error.
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('상품 ID –', style: subStyle),
                                    const InfoBubbleIcon(
                                      message: '마켓 등록 후 부여',
                                      size: 14,
                                    ),
                                  ],
                                ),
                              Text('·', style: subStyle),
                              Text('옵션 ${views.length}개', style: subStyle),
                              if (minPrice != null) ...[
                                Text('·', style: subStyle),
                                Text(
                                  '${formatWon(minPrice)}${hasPriceRange ? '~' : ''}',
                                  style: subStyle,
                                ),
                              ],
                              if (activeViews.isNotEmpty) ...[
                                Text('·', style: subStyle),
                                Text(
                                  '재고 ${koNumber(stockTotal)}',
                                  style: subStyle,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(status: status),
                        if (needsSync)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WarnChip(text: '변경 미반영'),
                              InfoBubbleIcon(message: _needsSyncHint, size: 14),
                            ],
                          ),
                        if (categoryMismatch)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _WarnChip(text: '카테고리 불일치'),
                              InfoBubbleIcon(
                                message: categoryLabel != null
                                    ? '$categoryLabel — $_ownCategoryHint'
                                    : _ownCategoryHint,
                                size: 14,
                              ),
                            ],
                          ),
                      ],
                    ),
                    CellActions(
                      masterId: widget.masterId,
                      listingId: listingId,
                      status: status,
                      options: widget.masterOptions,
                      onReload: widget.onReload,
                      accountId: widget.accountId,
                      platform: widget.platform,
                      channelLabel: widget.channelLabel,
                      shippingOverride: gen?.shippingOverride,
                      shippingReady: gen?.shippingReady,
                      onShippingSaved: (updated) =>
                          widget.onShippingSaved(listingId, updated),
                      usesOwnCategory: categoryMismatch,
                      channelCategoryLabel: categoryLabel,
                      masterCategoryName: widget.masterCategoryName,
                      // ⚠️ Own cell only — all cells would multiply the
                      // unlink/delete items.
                      cells: [cell],
                      onCellRemoved: widget.onCellRemoved,
                      needsMarketSync: needsSync,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_expanded)
            ListingDetailPanel(
              listingId: listingId,
              name: cell.name,
              registrationName: cell.registrationName,
              tags: gen?.tags ?? const [],
              onMarket: pid != null,
              options: views,
              optionsLoading: pending || widget.channelOptionsLoading,
              onEditMasterOption: widget.onEditMasterOption,
              onSaved: widget.onReload,
              thumbnail: bigThumb,
              detailThumb: detailThumb,
            ),
        ],
      ),
    );
  }
}

/// Status chip (web `STATUS_CHIP`).
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground) = switch (status) {
      ListingStatusCode.submitted => (
          AppColors.infoSurface,
          AppColors.infoForeground,
        ),
      ListingStatusCode.selling => (
          AppColors.successSurface,
          AppColors.successForeground,
        ),
      ListingStatusCode.rejected ||
      ListingStatusCode.suspended =>
        (scheme.errorContainer, scheme.error),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        kListingStatusLabel[status] ?? status,
        style: TextStyle(fontSize: 11, color: foreground),
      ),
    );
  }
}

/// Amber chip (web `bg-amber-100 text-amber-800`).
class _WarnChip extends StatelessWidget {
  final String text;

  const _WarnChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.warningForeground,
          ),
        ),
      );
}
