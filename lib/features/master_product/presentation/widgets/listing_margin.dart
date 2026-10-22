import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';

/// Margin view parts of the master detail (FEATURE_2610_27 · FEATURE_2610_28)
/// — web `ListingMargin.tsx`.
///
/// **File**: lib/features/master_product/presentation/widgets/listing_margin.dart
///
/// - [MarginSummary]: the 「마진:」 value of an option card — amount + rate,
///   red when under the preset minimum (2610_27 D4 · D5), the reason instead
///   of numbers when it cannot be calculated (2610_27 D12), and 「마켓 가격
///   없음 — 시스템 가격 기준」 under a margin judged on the system price
///   (2610_27 D2). An ESM option shows a 「G」 line and an 「옥션」 line
///   (2610_27 D3).
/// - [MarginBreakdown]: what opens under the card's margin — one formula per
///   site, headed 「G마켓」 · 「옥션」 on an ESM option (2610_28 D4 · D9 · D21).
/// - [SiteBreakdown]: one formula (2610_28 D3 · D5 · D7 · D10 · D12 ~ D15) —
///   the price, 「− 상품 매입가」 with one line per component, 「− 상자비」,
///   「− 택배비」, 「− 판매 수수료」, 「− 배송비 수수료」 (only when not 0),
///   「= 마진」, 「손익분기가」, 「최소 마진 기준」 (only when set) and 「마켓 가격
///   확인: MM/DD HH:mm」 (only when known). When the margin cannot be
///   calculated: the reason, the price and the check time only.
/// - [MarginPreviewText]: the margin of a price typed in the price page, asked
///   300 ms after typing stops (2610_27 D6 · D20 · D38), with 「▸」 that opens
///   its formula below, as wide as the page (2610_28 D16 · D17). Saving is
///   never blocked (2610_27 D21).
///
/// ❌ Never compute a margin, a rate or a difference here — the numbers are
/// the server's (2610_27 D8 · D20 · 2610_28 D2).
const String kMarketPriceMissingNote = '마켓 가격 없음 — 시스템 가격 기준';

/// D38: how long typing must stop before the preview is asked.
const Duration _previewDelay = Duration(milliseconds: 300);

/// 2610_27 D3: the summary prefix of each ESM site (a single-site option has
/// none).
const Map<String, String> _summaryLabels = {'GMARKET': 'G ', 'AUCTION': '옥션 '};

/// 2610_28 D21: the formula heading of each ESM site.
const Map<String, String> _siteTitles = {'GMARKET': 'G마켓', 'AUCTION': '옥션'};

/// Web repricing `formatWon` — '—' when absent.
String _won(num? value) => value == null ? '—' : '${koNumber(value.round())}원';

/// Web repricing `formatPercent` — 0~1 → one decimal percent, '—' when absent.
String _percent(num? rate) =>
    rate == null ? '—' : '${koNumber((rate * 1000).round() / 10)}%';

/// D11 · D12: 「{amount} ({rate})」, or the reason when it cannot be calculated.
String marginText(SiteMargin site) =>
    site.reason ?? '${_won(site.marginAmount)} (${_percent(site.marginRate)})';

/// D26 · D32: the KST wall clock as 「MM/DD HH:mm」 — no time zone conversion.
String marketCheckedText(String marketPriceAt) => '마켓 가격 확인: '
    '${formatOrderDateTime(marketPriceAt).substring(5).replaceFirst('-', '/')}';

/// 2610_28 D13: 「3,000원 · 10.0%」 — only the minimums that are set; '' when
/// neither is.
String _minimumText(SiteMargin s) {
  final amount = s.minMarginAmount;
  final rate = s.minMarginRate;
  return [
    if (amount != null) _won(amount),
    if (rate != null) '${((rate * 1000).round() / 10).toStringAsFixed(1)}%',
  ].join(' · ');
}

/// Text color of one margin line: grey reason · red below · default.
Color? _marginColor(BuildContext context, SiteMargin site) {
  final scheme = Theme.of(context).colorScheme;
  if (site.reason != null) {
    return scheme.onSurfaceVariant;
  }
  return site.below ? scheme.error : null;
}

class MarginSummary extends StatelessWidget {
  final OptionMargin margin;

  const MarginSummary({required this.margin, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final multi = margin.sites.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final site in margin.sites) ...[
          Text(
            '${multi ? (_summaryLabels[site.site] ?? '') : ''}'
            '${marginText(site)}',
            style: TextStyle(
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: _marginColor(context, site),
            ),
          ),
          if (site.marketPriceMissing)
            Text(
              kMarketPriceMissingNote,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
        ],
      ],
    );
  }
}

/// Green for a margin that meets the minimum (web `text-emerald-700`).
const Color _okColor = Color(0xFF047857);

/// 2610_28 D4: one line that takes part in the calculation — operator column,
/// name on the left, amount right-aligned. Reference lines (component detail,
/// break-even, minimum) use [_DetailLine] / [_InfoLine] so what is summed and
/// what only explains it never look alike.
class _FormulaLine extends StatelessWidget {
  /// '−' for a deducted amount, '=' for the margin, '' for the price.
  final String sign;
  final String label;
  final String amount;

  /// The 「= 마진」 line: a rule above, bold, green or red (2610_28 D4).
  final bool total;
  final bool below;

  const _FormulaLine({
    required this.label,
    required this.amount,
    this.sign = '',
    this.total = false,
    this.below = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weight = total ? FontWeight.w600 : FontWeight.w400;
    final tone = total ? (below ? scheme.error : _okColor) : scheme.onSurface;
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 14,
          child: Text(
            sign,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: weight,
              color: total ? tone : scheme.outline,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: weight,
              color: total ? tone : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: weight,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: tone,
          ),
        ),
      ],
    );
    if (total) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: line,
      );
    }
    return Padding(padding: const EdgeInsets.only(top: 2), child: line);
  }
}

/// A component under 「상품 매입가」 (2610_28 D7 · D14): explanation only, not
/// added again — lighter, smaller, figures in parentheses as
/// 「(단가 × 수량 = 금액)」.
class _DetailLine extends StatelessWidget {
  final CostComponent component;

  const _DetailLine({required this.component});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final faint = TextStyle(
      fontSize: 11,
      color: scheme.outline,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final c = component;
    final unitPrice = c.unitPrice;
    final amount = c.amount;
    final figures = unitPrice == null || amount == null
        ? TextSpan(children: [
            const TextSpan(text: '('),
            TextSpan(text: '단가 없음', style: TextStyle(color: scheme.error)),
            TextSpan(text: ' × ${c.quantity})'),
          ])
        : TextSpan(
            text: '(${_won(unitPrice)} × ${c.quantity} = ${_won(amount)})');
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 2),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: scheme.outlineVariant, width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              c.productName,
              style: faint,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text.rich(figures, style: faint),
        ],
      ),
    );
  }
}

/// A reference line below the margin (break-even, minimum) — not part of the
/// calculation.
class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class SiteBreakdown extends StatelessWidget {
  final SiteMargin site;

  /// 2610_28 D9: 「G마켓」 · 「옥션」 above the formula of an ESM site; null =
  /// no heading.
  final String? title;

  /// 2610_28 D16 · D17: 「입력한 가격」 on the price page; null = 「마켓 가격」
  /// or 「시스템 가격 (마켓 가격 없음)」 (D5).
  final String? priceLabel;

  const SiteBreakdown({
    required this.site,
    required this.title,
    required this.priceLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = site;
    final firstLabel =
        priceLabel ?? (s.marketPriceMissing ? '시스템 가격 (마켓 가격 없음)' : '마켓 가격');
    final minimum = _minimumText(s);
    final note = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    final heading = title;
    final reason = s.reason;
    final checkedAt = s.marketPriceAt;
    final shippingFeeCommission = s.shippingFeeCommission;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Text(
                heading,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
          if (reason != null) ...[
            Text(reason, style: note),
            _FormulaLine(label: firstLabel, amount: _won(s.judgedPrice)),
          ] else ...[
            _FormulaLine(label: firstLabel, amount: _won(s.judgedPrice)),
            _FormulaLine(sign: '−', label: '상품 매입가', amount: _won(s.costSum)),
            for (final c in s.components) _DetailLine(component: c),
            _FormulaLine(sign: '−', label: '상자비', amount: _won(s.box)),
            _FormulaLine(sign: '−', label: '택배비', amount: _won(s.delivery)),
            _FormulaLine(
              sign: '−',
              label: '판매 수수료 (${_percent(s.commissionRate)}, 부가세 포함)',
              amount: _won(s.commissionAmount),
            ),
            if (shippingFeeCommission != null && shippingFeeCommission > 0)
              _FormulaLine(
                sign: '−',
                label: '배송비 수수료 (3.3%)',
                amount: _won(shippingFeeCommission),
              ),
            _FormulaLine(
              sign: '=',
              total: true,
              below: s.below,
              label: '마진 (${_percent(s.marginRate)})',
              amount: _won(s.marginAmount),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: scheme.outlineVariant),
            _InfoLine(label: '손익분기가', value: _won(s.breakEvenPrice)),
            if (minimum.isNotEmpty)
              _InfoLine(label: '최소 마진 기준', value: minimum),
          ],
          if (checkedAt != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  marketCheckedText(checkedAt),
                  style: TextStyle(fontSize: 10, color: scheme.outline),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MarginBreakdown extends StatelessWidget {
  final OptionMargin margin;

  const MarginBreakdown({required this.margin, super.key});

  @override
  Widget build(BuildContext context) {
    final multi = margin.sites.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, site) in margin.sites.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          SiteBreakdown(
            site: site,
            title: multi ? (_siteTitles[site.site] ?? site.site) : null,
            priceLabel: null,
          ),
        ],
      ],
    );
  }
}

/// The margin line and, once 「▸」 is tapped, the formula of the same answer
/// below it, as wide as the page (2610_28 D16 · D17). A new price hides the
/// formula until its answer arrives; the open state stays.
class MarginPreviewText extends StatefulWidget {
  final int listingId;
  final int optionId;

  /// 2610_28 D20 · D21: the site the price is for — the listing's platform, or
  /// 'GMARKET' · 'AUCTION' on ESM.
  final String site;

  /// The price typed in; null = not a valid price (nothing asked or shown).
  final num? price;

  const MarginPreviewText({
    required this.listingId,
    required this.optionId,
    required this.site,
    required this.price,
    super.key,
  });

  @override
  State<MarginPreviewText> createState() => _MarginPreviewTextState();
}

class _MarginPreviewTextState extends State<MarginPreviewText> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();
  Timer? _timer;
  num? _answeredPrice;
  SiteMargin? _site;
  String _error = '';
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant MarginPreviewText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price ||
        oldWidget.optionId != widget.optionId ||
        oldWidget.site != widget.site) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    final price = widget.price;
    if (price == null) {
      return;
    }
    _timer = Timer(_previewDelay, () => unawaited(_ask(price)));
  }

  Future<void> _ask(num price) async {
    final res = await _useCase.previewMargin(widget.listingId, widget.optionId,
        price: price, site: widget.site);
    if (!mounted || widget.price != price) {
      return;
    }
    setState(() {
      _answeredPrice = price;
      res.fold(
        (failure) {
          _site = null;
          _error = failureText(failure, '마진을 계산하지 못했습니다.');
        },
        (site) {
          _site = site;
          _error = '';
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = widget.price;
    if (price == null) {
      return const SizedBox.shrink();
    }
    if (_answeredPrice != price) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final site = _site;
    if (site == null) {
      return Text(_error,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant));
    }
    final text =
        site.reason == null ? '마진 ${marginText(site)}' : marginText(site);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Text(
            '$text ${_open ? '▾' : '▸'}',
            style: TextStyle(
              fontSize: 11,
              color: _marginColor(context, site) ?? scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SiteBreakdown(
              site: site,
              title: _siteTitles[widget.site],
              priceLabel: '입력한 가격',
            ),
          ),
        ],
      ],
    );
  }
}
