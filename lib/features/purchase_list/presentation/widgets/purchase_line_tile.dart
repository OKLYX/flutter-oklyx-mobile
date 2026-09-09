import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/purchase_line.dart';
import '../../domain/entities/purchase_record.dart';

/// 금액 입력 모드 (PLAN 2609_28 D2) — 영수증 표기가 총액/단가 어느 쪽이든 받는다.
enum _AmountMode { total, unit }

/// 구매목록 라인 1개 타일 (펼쳐진 상품 카드 내부).
///
/// 표시: 주문/수동 배지, 주문번호(externalOrderId), `필요 N (자동 a + 수동 m) · 구매 p`,
/// 구매기록 목록(음수는 빨강, 금액 없으면 `금액 미상`, 기준가 미반영이면 꼬리표). 인라인 폼 2개:
///  - 구매기록: 날짜(date picker) + 수량(정수, 0 불가, 음수 허용)
///    + 금액(총액/단가 토글, 빈 값 허용) + `상품 기준가에 반영` 체크박스 → [onRecordPurchase]
///  - 수동수량 교체: 정수(0+) → [onAdjustManual]
///
/// 금액은 총액/단가 중 **한쪽만** 콜백으로 넘어간다 — 나머지는 서버가 계산한다(PLAN 2609_28 D1).
/// 환산 미리보기는 화면 표시용이며 전송 값에 반올림을 적용하지 않는다.
///
/// [busy]가 true면(조회/재적재/액션 진행 중) 폼 버튼을 비활성화한다.
class PurchaseLineTile extends StatefulWidget {
  final PurchaseLine line;
  final bool busy;

  /// 읽기전용(완료 탭)이면 인라인 폼을 숨기고 기록만 표시한다.
  final bool readOnly;
  final void Function(
    int itemId,
    String purchasedOn,
    int quantity, {
    double? totalAmount,
    double? unitPrice,
    bool reflectToBasePrice,
  }) onRecordPurchase;
  final void Function(int itemId, int manualQty) onAdjustManual;

  const PurchaseLineTile({
    required this.line,
    required this.busy,
    required this.onRecordPurchase,
    required this.onAdjustManual,
    this.readOnly = false,
    super.key,
  });

  @override
  State<PurchaseLineTile> createState() => _PurchaseLineTileState();
}

class _PurchaseLineTileState extends State<PurchaseLineTile> {
  /// 천단위 구분 + 소수 2자리까지. 총액 10,000 / 수량 3 → `@3,333.33`.
  static final NumberFormat _amountFormat = NumberFormat('#,##0.##', 'ko_KR');

  DateTime _purchasedOn = DateTime.now();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _manualController = TextEditingController();
  _AmountMode _amountMode = _AmountMode.total;
  bool _reflectToBasePrice = true;

  @override
  void initState() {
    super.initState();
    _manualController.text = widget.line.manualQty.toString();
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
    _manualController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  /// 입력된 금액(콤마 허용). 빈 값이면 null, 형식이 틀리면 null 이며 [_submitRecord] 가 막는다.
  double? _parsedAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// 총액 모드 `@단가`, 단가 모드 `계 총액`. 수량 0/미입력이거나 금액이 비면 null.
  String? _amountPreview() {
    final qty = int.tryParse(_qtyController.text.trim());
    final amount = _parsedAmount();
    if (qty == null || qty == 0 || amount == null) return null;
    return _amountMode == _AmountMode.total
        ? '@${_amountFormat.format(amount / qty)}'
        : '계 ${_amountFormat.format(amount * qty)}';
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

  void _submitRecord() {
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty == 0) {
      _toast('수량은 0이 아닌 정수여야 합니다.');
      return;
    }
    final rawAmount = _amountController.text.trim();
    final amount = _parsedAmount();
    if (rawAmount.isNotEmpty && (amount == null || amount < 0)) {
      _toast('금액은 0 이상의 숫자여야 합니다.');
      return;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(_purchasedOn);
    // 총액/단가 중 한쪽만 넘긴다 — 나머지 계산·반올림은 서버가 한다(PLAN 2609_28 D1).
    widget.onRecordPurchase(
      widget.line.itemId,
      dateStr,
      qty,
      totalAmount: _amountMode == _AmountMode.total ? amount : null,
      unitPrice: _amountMode == _AmountMode.unit ? amount : null,
      reflectToBasePrice: _reflectToBasePrice,
    );
    _qtyController.clear();
    _amountController.clear();
    setState(() {
      _amountMode = _AmountMode.total;
      _reflectToBasePrice = true;
    });
  }

  void _submitManual() {
    final value = int.tryParse(_manualController.text.trim());
    if (value == null || value < 0) {
      _toast('수동수량은 0 이상의 정수여야 합니다.');
      return;
    }
    widget.onAdjustManual(widget.line.itemId, value);
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

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final preview = _amountPreview();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sourceBadge(line.isManual),
              if (line.externalOrderId != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    line.externalOrderId!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '필요 ${line.neededQty} (자동 ${line.autoQty} + 수동 ${line.manualQty}) · 구매 ${line.purchasedQty}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (line.records.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...line.records.map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _recordText(r),
              ),
            ),
          ],
          if (!widget.readOnly) ...[
            const Divider(height: 18),

            // 구매기록 입력 폼
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: widget.busy ? null : _pickDate,
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_purchasedOn),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: widget.busy ? null : _submitRecord,
                  child: const Text('기록'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 금액 입력: 총액/단가 토글 + 금액 + 환산 미리보기
            Row(
              children: [
                SizedBox(width: 116, child: _amountModeSelector()),
                const SizedBox(width: 6),
                Expanded(
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
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                if (preview != null) ...[
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Text(
                      preview,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ],
            ),

            // 기준가 반영 여부 (PLAN 2609_28 D3) — 끄면 판매가 파급 대상에서 빠진다.
            CheckboxListTile(
              value: _reflectToBasePrice,
              onChanged: widget.busy
                  ? null
                  : (v) => setState(() => _reflectToBasePrice = v ?? true),
              title: const Text('상품 기준가에 반영',
                  style: TextStyle(fontSize: 13)),
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
            const SizedBox(height: 4),

            // 수동수량 교체 폼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '수동수량',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: widget.busy ? null : _submitManual,
                  child: const Text('교체'),
                ),
              ],
            ),
          ],
        ],
      ),
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

  /// `· 2026-09-07  +3   12,000원 (@4,000) · 기준가 미반영`
  /// 금액이 없으면 `금액 미상` — `0원` 으로 쓰지 않는다(PLAN 2609_28 D1).
  Widget _recordText(PurchaseRecord r) {
    final baseColor = r.quantity < 0 ? Colors.red : Colors.grey[700];
    final mutedColor = Colors.grey[500];
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 12, color: baseColor),
        children: [
          TextSpan(
            text: '· ${r.purchasedOn}  ${r.quantity > 0 ? '+' : ''}${r.quantity}',
          ),
          if (r.totalAmount == null)
            TextSpan(
              text: '   금액 미상',
              style: TextStyle(color: mutedColor),
            )
          else
            TextSpan(
              text: '   ${_amountFormat.format(r.totalAmount)}원'
                  '${r.unitPrice == null ? '' : ' (@${_amountFormat.format(r.unitPrice)})'}',
            ),
          if (!r.reflectToBasePrice)
            TextSpan(
              text: ' · 기준가 미반영',
              style: TextStyle(color: mutedColor),
            ),
        ],
      ),
    );
  }

  Widget _sourceBadge(bool isManual) {
    final color = isManual ? Colors.purple : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isManual ? '수동' : '주문',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }
}
