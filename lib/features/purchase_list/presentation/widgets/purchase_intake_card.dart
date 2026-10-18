import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/purchase_record.dart';
import '../../domain/usecases/get_recent_purchases_usecase.dart';
import 'receipt_detail_sheet.dart';
import 'seller_filter_dropdown.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';

/// 금액 입력 모드 (PLAN 2609_28 D2) — 영수증 표기가 총액/단가 어느 쪽이든 받는다.
enum _AmountMode { total, unit }

/// Intake card — the per-product purchase input (PLAN 2609_29 D1). The receipt
/// popup (`ReceiptIntakeSheet`, FEATURE_2610_18 D46 · D75) is the other way in.
///
/// **Purpose**: records "this seller brought in this many of this product" once.
/// No form per line (order) — purchase records do not know orders (D3 · D7).
/// **File**: `lib/features/purchase_list/presentation/widgets/purchase_intake_card.dart`
/// **Rule**: the list tab and the completed tab use **the same widget** (D21) —
/// no copy for the completed tab.
///
/// **Layout** (2026-10-08): fixed-width label on the left, input on the right,
/// one per line.
/// - 「판매자」: `SellerFilterDropdown(includeAll: false, labelText: null)` — starts
///   at [initialSellerId] (the page's seller filter, FEATURE_2610_09 D9) and
///   returns to it after [입고하기] (D10). Hidden when [hideSeller] (one seller,
///   D53) — [initialSellerId] is then that seller.
/// - 「구매일」 / 「수량」 (「개」, negative = correction) / 「금액」 (「총액」·「단가」
///   toggle + 「원」, empty = amount not entered) → conversion under the amount
///   (「개당 N원」 / 「합계 N원」)
/// - 「상품 기준가에 반영」 checkbox (D14) — explained under it when off
/// - full-width [입고하기] + 「입고하면 재고에 바로 더해집니다」 under it while
///   [stockLinked] (D71 ③). **No stock switch** — the server follows the stock
///   link setting; `recordStock: true` is always sent (FEATURE_2610_09 D65).
/// - [입고하기] is disabled without a seller or with quantity 0 / empty
///
/// **Recent purchases** (D9 · FEATURE_2610_09 D7 · D25)
/// [최근 구매이력 ▾] at the bottom, folded by default. Every opening starts at
/// 「전체」 and calls `GetRecentPurchasesUseCase` **from the widget** (rows kept
/// locally, not in the BLoC — N products would mean N states). A 「판매자」
/// dropdown above the rows filters one seller (hidden when [hideSeller]).
/// A row that came with a receipt has [영수증] → `ReceiptDetailSheet`
/// (FEATURE_2610_18 D93 ①); a header edit there reloads the rows and calls
/// [onReceiptEdited] (D100).
/// After [입고하기] the rows are dropped and the box folds.
///
/// ❌ Do not keep recent purchases in `PurchaseListBloc`
class PurchaseIntakeCard extends StatefulWidget {
  final int productId;
  final List<Seller> sellers;

  /// Seller field start value (FEATURE_2610_09 D9 · D10 · D53).
  final int? initialSellerId;

  /// One seller → no seller fields (D53).
  final bool hideSeller;

  /// Stock link setting — the 「입고하면 재고에 바로 더해집니다」 line (D71 ③).
  final bool stockLinked;

  /// 목록 조회/액션 진행 중이면 폼을 비활성화한다.
  final bool busy;

  /// 입고 제출 — 상위(BLoC)가 `RecordPurchase` 이벤트로 옮긴다.
  final void Function({
    required int sellerId,
    required String purchasedOn,
    required int quantity,
    double? totalAmount,
    double? unitPrice,
    required bool reflectToBasePrice,
  }) onSubmit;

  /// A receipt header was edited from a recent purchase row (FEATURE_2610_18
  /// D100) — the page reloads its numbers.
  final VoidCallback onReceiptEdited;

  const PurchaseIntakeCard({
    required this.productId,
    required this.sellers,
    required this.initialSellerId,
    required this.hideSeller,
    required this.stockLinked,
    required this.busy,
    required this.onSubmit,
    required this.onReceiptEdited,
    super.key,
  });

  @override
  State<PurchaseIntakeCard> createState() => _PurchaseIntakeCardState();
}

class _PurchaseIntakeCardState extends State<PurchaseIntakeCard> {
  /// 천단위 구분 + 소수 2자리까지. 총액 10,000 / 수량 3 → `@3,333.33`.
  static final NumberFormat _amountFormat = NumberFormat('#,##0.##', 'ko_KR');
  static const int _recentLimit = 5;

  late int? _sellerId = widget.initialSellerId;
  DateTime _purchasedOn = DateTime.now();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  _AmountMode _amountMode = _AmountMode.total;
  bool _reflectToBasePrice = true;

  // 최근 구매이력 — 위젯 로컬 상태(PLAN 2609_29 D9).
  bool _historyExpanded = false;
  int? _historySellerId;
  bool _historyLoading = false;
  String? _historyError;
  List<PurchaseRecord>? _records;

  @override
  void initState() {
    super.initState();
    // 환산 미리보기는 수량·금액 양쪽에 반응한다.
    _qtyController.addListener(_onFormChanged);
    _amountController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _qtyController.removeListener(_onFormChanged);
    _amountController.removeListener(_onFormChanged);
    _qtyController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  /// Typed amount (commas allowed). Blank → null = amount not entered
  /// (FEATURE_2610_18 D68 「미기입」).
  double? _parsedAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  int? _parsedQty() => int.tryParse(_qtyController.text.trim());

  /// 총액 모드 `개당 N원`, 단가 모드 `합계 N원`. 수량 0/미입력이거나 금액이 비면 null.
  String? _amountPreview() {
    final qty = _parsedQty();
    final amount = _parsedAmount();
    if (qty == null || qty == 0 || amount == null) return null;
    return _amountMode == _AmountMode.total
        ? '개당 ${_amountFormat.format(amount / qty)}원'
        : '합계 ${_amountFormat.format(amount * qty)}원';
  }

  bool get _canSubmit {
    final qty = _parsedQty();
    return !widget.busy && _sellerId != null && qty != null && qty != 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedOn,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _purchasedOn = picked);
    }
  }

  void _submit() {
    final sellerId = _sellerId;
    final qty = _parsedQty();
    if (sellerId == null || qty == null || qty == 0) return;

    final rawAmount = _amountController.text.trim();
    final amount = _parsedAmount();
    if (rawAmount.isNotEmpty && (amount == null || amount < 0)) {
      _toast('금액은 0 이상의 숫자여야 합니다.');
      return;
    }

    // 총액/단가 중 한쪽만 넘긴다 — 나머지 계산·반올림은 서버가 한다(PLAN 2609_28 D1).
    widget.onSubmit(
      sellerId: sellerId,
      purchasedOn: DateFormat('yyyy-MM-dd').format(_purchasedOn),
      quantity: qty,
      totalAmount: _amountMode == _AmountMode.total ? amount : null,
      unitPrice: _amountMode == _AmountMode.unit ? amount : null,
      reflectToBasePrice: _reflectToBasePrice,
    );

    _qtyController.clear();
    _amountController.clear();
    setState(() {
      _sellerId = widget.initialSellerId;
      _amountMode = _AmountMode.total;
      _reflectToBasePrice = true;
      // 방금 넣은 건이 빠진 이력을 보여주지 않도록 캐시를 비우고 접는다.
      _historyExpanded = false;
      _historyLoading = false;
      _historyError = null;
      _records = null;
    });
  }

  /// Only input prompts pass through here — kind = input notice
  /// (FEATURE_2610_02 · N13).
  void _toast(String message) {
    showInputNoticeToast(context, message);
  }

  /// D25: every opening starts at 「전체」 and loads again.
  Future<void> _toggleHistory() async {
    final willExpand = !_historyExpanded;
    setState(() {
      _historyExpanded = willExpand;
      _historySellerId = null;
    });
    if (willExpand) await _loadHistory();
  }

  /// The box's own seller filter, separate from the page's (D25).
  Future<void> _changeHistorySeller(int? sellerId) async {
    setState(() => _historySellerId = sellerId);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    final result = await getIt<GetRecentPurchasesUseCase>()(
      widget.productId,
      limit: _recentLimit,
      sellerId: _historySellerId,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _historyLoading = false;
        _historyError = failure.message;
      }),
      (records) => setState(() {
        _historyLoading = false;
        _records = records;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _amountPreview();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        border: Border.all(color: AppColors.infoSurface),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '입고 기록',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 판매자 (필수) — '전체' 옵션 없음. 라벨은 왼쪽 칸이 그린다.
          if (!widget.hideSeller)
            _field(
              '판매자',
              SellerFilterDropdown(
                sellers: widget.sellers,
                selectedSellerId: _sellerId,
                enabled: !widget.busy,
                includeAll: false,
                labelText: null,
                onChanged: (value) => setState(() => _sellerId = value),
              ),
            ),
          _field(
            '구매일',
            OutlinedButton.icon(
              onPressed: widget.busy ? null : _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                DateFormat('yyyy-MM-dd').format(_purchasedOn),
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          _field(
            '수량',
            TextField(
              controller: _qtyController,
              enabled: !widget.busy,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
              ],
              decoration: const InputDecoration(
                hintText: '예: 3  (정정은 -3)',
                suffixText: '개',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
            ),
          ),
          _field(
            '금액',
            Row(
              children: [
                SizedBox(width: 116, child: _amountModeSelector()),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    enabled: !widget.busy,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      hintText: '모르면 비움',
                      suffixText: '원',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.only(left: _labelWidth, bottom: 6),
              child: Text(
                '→ $preview',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),

          // 기준가 반영 여부 (PLAN 2609_28 D3) — 끄면 판매가 파급 대상에서 빠진다.
          CheckboxListTile(
            value: _reflectToBasePrice,
            onChanged: widget.busy
                ? null
                : (v) => setState(() => _reflectToBasePrice = v ?? true),
            title: const Text('상품 기준가에 반영', style: TextStyle(fontSize: 13)),
            subtitle: _reflectToBasePrice
                ? null
                : Text(
                    '이번 매입가는 손익에만 쓰이고 판매가에는 반영되지 않습니다',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: const Text('입고하기'),
            ),
          ),
          // D71 ③: shown only while the stock link is on — no switch here.
          if (widget.stockLinked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  '입고하면 재고에 바로 더해집니다',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ),
          const Divider(height: 16),

          // 최근 구매이력 (기본 접힘)
          InkWell(
            onTap: _toggleHistory,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Text('최근 구매이력', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Icon(
                    _historyExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_historyExpanded && !widget.hideSeller)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SellerFilterDropdown(
                sellers: widget.sellers,
                selectedSellerId: _historySellerId,
                enabled: !_historyLoading,
                onChanged: _changeHistorySeller,
              ),
            ),
          if (_historyExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildHistory(),
            ),
        ],
      ),
    );
  }

  static const double _labelWidth = 56;

  /// One labelled form row: fixed-width label on the left, control on the right.
  Widget _field(String label, Widget control) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: _labelWidth,
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: control),
          ],
        ),
      );

  Widget _buildHistory() {
    if (_historyLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_historyError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          _historyError!,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }
    final records = _records ?? const <PurchaseRecord>[];
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '구매 이력 없음',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: records
          .map((r) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _recordText(r),
              ))
          .toList(),
    );
  }

  Widget _amountModeSelector() {
    return SegmentedButton<_AmountMode>(
      segments: const [
        ButtonSegment(value: _AmountMode.total, label: Text('총액')),
        ButtonSegment(value: _AmountMode.unit, label: Text('단가')),
      ],
      selected: {_amountMode},
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -3, vertical: -3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
      ),
      onSelectionChanged:
          widget.busy ? null : (set) => setState(() => _amountMode = set.first),
    );
  }

  /// 「09-09 · A상사 · +3 · 6,000원 (@2,000) · 기준가 미반영」 + [영수증] when the
  /// purchase came with a receipt (FEATURE_2610_18 D93 ①).
  /// No amount → 「미기입」 (D68) — never 「0원」 (PLAN 2609_28 D1).
  Widget _recordText(PurchaseRecord r) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = r.quantity < 0 ? scheme.error : scheme.onSurfaceVariant;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final date =
        r.purchasedOn.length >= 10 ? r.purchasedOn.substring(5) : r.purchasedOn;
    final text = Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: baseColor),
        children: [
          TextSpan(
            text: '$date · ${r.sellerName} · '
                '${r.quantity > 0 ? '+' : ''}${r.quantity}',
          ),
          if (r.totalAmount == null)
            TextSpan(text: ' · 미기입', style: TextStyle(color: mutedColor))
          else
            TextSpan(
              text: ' · ${_amountFormat.format(r.totalAmount)}원'
                  '${r.unitPrice == null ? '' : ' (@${_amountFormat.format(r.unitPrice)})'}',
            ),
          if (!r.reflectToBasePrice)
            TextSpan(text: ' · 기준가 미반영', style: TextStyle(color: mutedColor)),
        ],
      ),
    );
    final receiptId = r.receiptId;
    if (receiptId == null) return text;
    return Row(
      children: [
        Expanded(child: text),
        TextButton(
          onPressed: () => showAppSheet<void>(
            context,
            builder: (_) => ReceiptDetailSheet(
              receiptId: receiptId,
              sellers: widget.sellers,
              onEdited: () {
                // D100: the line may have moved to another seller or day.
                if (_historyExpanded) _loadHistory();
                widget.onReceiptEdited();
              },
            ),
          ),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('영수증', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
