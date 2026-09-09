import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import '../../domain/entities/purchase_record.dart';
import '../../domain/usecases/get_recent_purchases_usecase.dart';
import 'seller_filter_dropdown.dart';

/// 금액 입력 모드 (PLAN 2609_28 D2) — 영수증 표기가 총액/단가 어느 쪽이든 받는다.
enum _AmountMode { total, unit }

/// 입고 카드 — 그룹(물품) 토글 최상단의 **유일한 구매 입력창** (PLAN 2609_29 D1).
///
/// **용도**: "이 판매자가 이 물품을 이만큼 들였다"를 1회로 기록한다. 라인(주문)마다
/// 폼을 두지 않는다 — 구매기록은 주문을 모른다(D3·D7).
/// **위치**: `lib/features/purchase_list/presentation/widgets/purchase_intake_card.dart`
/// **필수 규칙**: 구매목록 탭과 완료 탭이 **같은 위젯**을 쓴다(D21) — 완료탭용 복제 금지.
///
/// **컨트롤**
/// - 판매자: `SellerFilterDropdown(includeAll: false)` · 기본 미선택
/// - 구매일 / 기준(총액·단가) / 수량(음수=정정) / 금액(빈칸=금액 미상) / 기준가 반영(D14)
/// - 재고 즉시 반영: **체크 + 비활성**(D19) — 전송은 항상 `recordStock: true`
/// - [입고]: 판매자 미선택 또는 수량 0/미입력이면 비활성
///
/// **최근 구매이력**(D9)
/// 카드 하단 [최근 구매이력 ▾]. 기본 접힘. 펼칠 때 `GetRecentPurchasesUseCase` 를
/// **위젯이 직접** 호출해 로컬 상태로 들고 있다 — BLoC 에 담지 않는다(그룹 N개면 상태도 N벌).
/// 판매자 조건이 없어 다른 판매자 건도 함께 보인다. 한 번 부른 뒤 접었다 펴면 재호출하지 않고,
/// [입고] 후에는 캐시를 비우고 접는다(방금 넣은 건이 안 보이면 이상하다).
///
/// ❌ 최근 구매이력을 `PurchaseListBloc` 에 담지 말 것
/// ❌ 이력 조회에 `sellerId` 조건을 걸지 말 것
class PurchaseIntakeCard extends StatefulWidget {
  final int productId;
  final List<Seller> sellers;

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

  const PurchaseIntakeCard({
    required this.productId,
    required this.sellers,
    required this.busy,
    required this.onSubmit,
    super.key,
  });

  @override
  State<PurchaseIntakeCard> createState() => _PurchaseIntakeCardState();
}

class _PurchaseIntakeCardState extends State<PurchaseIntakeCard> {
  /// 천단위 구분 + 소수 2자리까지. 총액 10,000 / 수량 3 → `@3,333.33`.
  static final NumberFormat _amountFormat = NumberFormat('#,##0.##', 'ko_KR');
  static const int _recentLimit = 5;

  int? _sellerId;
  DateTime _purchasedOn = DateTime.now();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  _AmountMode _amountMode = _AmountMode.total;
  bool _reflectToBasePrice = true;

  // 최근 구매이력 — 위젯 로컬 상태(PLAN 2609_29 D9).
  bool _historyExpanded = false;
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

  /// 입력된 금액(콤마 허용). 빈 값이면 null = 금액 미상.
  double? _parsedAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  int? _parsedQty() => int.tryParse(_qtyController.text.trim());

  /// 총액 모드 `@단가`, 단가 모드 `계 총액`. 수량 0/미입력이거나 금액이 비면 null.
  String? _amountPreview() {
    final qty = _parsedQty();
    final amount = _parsedAmount();
    if (qty == null || qty == 0 || amount == null) return null;
    return _amountMode == _AmountMode.total
        ? '@${_amountFormat.format(amount / qty)}'
        : '계 ${_amountFormat.format(amount * qty)}';
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
      _amountMode = _AmountMode.total;
      _reflectToBasePrice = true;
      // 방금 넣은 건이 빠진 이력을 보여주지 않도록 캐시를 비우고 접는다.
      _historyExpanded = false;
      _historyLoading = false;
      _historyError = null;
      _records = null;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
        ),
      );
  }

  /// 펼칠 때 한 번만 조회한다 — 이미 받아둔 캐시가 있으면 재호출하지 않는다.
  Future<void> _toggleHistory() async {
    final willExpand = !_historyExpanded;
    setState(() => _historyExpanded = willExpand);
    if (!willExpand || _records != null || _historyLoading) return;

    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    final result = await getIt<GetRecentPurchasesUseCase>()(
      widget.productId,
      limit: _recentLimit,
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
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '입고',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // 판매자 (필수) — '전체' 옵션 없음
          SellerFilterDropdown(
            sellers: widget.sellers,
            selectedSellerId: _sellerId,
            enabled: !widget.busy,
            includeAll: false,
            onChanged: (value) => setState(() => _sellerId = value),
          ),
          const SizedBox(height: 8),

          // 구매일 + 기준(총액/단가)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.busy ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    DateFormat('yyyy-MM-dd').format(_purchasedOn),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(width: 116, child: _amountModeSelector()),
            ],
          ),
          const SizedBox(height: 6),

          // 수량 + 금액 + 환산 미리보기
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '수량',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    hintText: _amountMode == _AmountMode.total ? '총액' : '단가',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (preview != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                preview,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),

          // 기준가 반영 여부 (PLAN 2609_28 D3) — 끄면 판매가 파급 대상에서 빠진다.
          CheckboxListTile(
            value: _reflectToBasePrice,
            onChanged: widget.busy
                ? null
                : (v) => setState(() => _reflectToBasePrice = v ?? true),
            title: const Text('상품 기준가에 반영', style: TextStyle(fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!_reflectToBasePrice)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '이번 매입가는 손익에만 쓰이고 판매가에는 반영되지 않습니다',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),

          // 재고 즉시 반영 — 체크 + 비활성(PLAN 2609_29 D19).
          // ❌ 켜고 끌 수 있게 두지 말 것 — 끄면 입고대기 건을 치울 화면이 아직 없다.
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: true,
                  onChanged: null,
                  title: Row(
                    children: [
                      const Flexible(
                        child: Text('재고 즉시 반영',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '(입고대기 화면 준비 중)',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                child: const Text('입고'),
              ),
            ],
          ),

          // 최근 구매이력 (기본 접힘)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _toggleHistory,
              icon: Icon(
                _historyExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: const Text('최근 구매이력', style: TextStyle(fontSize: 13)),
            ),
          ),
          if (_historyExpanded) _buildHistory(),
        ],
      ),
    );
  }

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
          style: TextStyle(fontSize: 12, color: Colors.red[700]),
        ),
      );
    }
    final records = _records ?? const <PurchaseRecord>[];
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '구매 이력 없음',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      onSelectionChanged: widget.busy
          ? null
          : (set) => setState(() => _amountMode = set.first),
    );
  }

  /// `09-09 · A상사 · +3 · 6,000원 (@2,000) · 기준가 미반영`
  /// 금액이 없으면 `금액 미상` — `0원` 으로 쓰지 않는다(PLAN 2609_28 D1).
  Widget _recordText(PurchaseRecord r) {
    final baseColor = r.quantity < 0 ? Colors.red : Colors.grey[700];
    final mutedColor = Colors.grey[500];
    final date =
        r.purchasedOn.length >= 10 ? r.purchasedOn.substring(5) : r.purchasedOn;
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: baseColor),
        children: [
          TextSpan(
            text: '$date · ${r.sellerName} · '
                '${r.quantity > 0 ? '+' : ''}${r.quantity}',
          ),
          if (r.totalAmount == null)
            TextSpan(text: ' · 금액 미상', style: TextStyle(color: mutedColor))
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
  }
}
