import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/master_format.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';

/// Margin view parts of the master detail (FEATURE_2610_27) — web
/// `ListingMargin.tsx`.
///
/// **File**: lib/features/master_product/presentation/widgets/listing_margin.dart
///
/// - [MarginSummary]: the 「마진:」 value of an option card (D11) — amount +
///   rate, red when under the preset minimum (D4 · D5), the reason instead of
///   numbers when it cannot be calculated (D12), and 「마켓 가격 없음 — 시스템
///   가격 기준」 under a margin judged on the system price (D2). An ESM option
///   shows a 「G」 line and an 「옥션」 line (D3).
/// - [MarginBreakdown]: the line opened under the card's margin (D11) —
///   「마켓 가격 · 시스템 가격 · 원가합 · 택배비 · 박스비 · 수수료 · 손익분기가」,
///   then 「마켓 가격 확인: MM/DD HH:mm」 when the check time is known (D26 ·
///   D35).
/// - [MarginPreviewText]: the margin of a price typed in the price page, asked
///   300 ms after typing stops (D6 · D20 · D38). Saving is never blocked (D21).
///
/// ❌ Never compute a margin here — the numbers are the server's (D8 · D20).
const String kMarketPriceMissingNote = '마켓 가격 없음 — 시스템 가격 기준';

/// D38: how long typing must stop before the preview is asked.
const Duration _previewDelay = Duration(milliseconds: 300);

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

/// D11: the seven parts of one price, in the order the decision lists them.
String _breakdownText(String label, SiteMargin s) =>
    '$label마켓 가격 ${_won(s.marketPrice)} · 시스템 가격 ${_won(s.systemPrice)} · '
    '원가합 ${_won(s.costSum)} · 택배비 ${_won(s.delivery)} · '
    '박스비 ${_won(s.box)} · 수수료 ${_won(s.feeAmount)} · '
    '손익분기가 ${_won(s.breakEvenPrice)}';

List<(String, SiteMargin)> _siteLines(OptionMargin m) {
  final auction = m.auctionMargin;
  return auction == null
      ? [('', m.margin)]
      : [('G ', m.margin), ('옥션 ', auction)];
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, site) in _siteLines(margin)) ...[
          Text(
            '$label${marginText(site)}',
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

class MarginBreakdown extends StatelessWidget {
  final OptionMargin margin;

  const MarginBreakdown({required this.margin, super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final checkedAt = margin.marketPriceAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, site) in _siteLines(margin))
          Text(_breakdownText(label, site), style: style),
        if (checkedAt != null) Text(marketCheckedText(checkedAt), style: style),
      ],
    );
  }
}

class MarginPreviewText extends StatefulWidget {
  final int listingId;
  final int optionId;

  /// true = the Auction field of an ESM option.
  final bool auction;

  /// The price typed in; null = not a valid price (nothing asked or shown).
  final num? price;

  const MarginPreviewText({
    required this.listingId,
    required this.optionId,
    required this.auction,
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
        oldWidget.auction != widget.auction) {
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
        price: price, auction: widget.auction);
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
    return Text(
      site.reason == null ? '마진 ${marginText(site)}' : marginText(site),
      style: TextStyle(
        fontSize: 11,
        color: _marginColor(context, site) ?? scheme.onSurfaceVariant,
      ),
    );
  }
}
