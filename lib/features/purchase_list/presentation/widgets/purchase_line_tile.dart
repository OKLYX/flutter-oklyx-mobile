import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/purchase_line.dart';

/// 구매목록 라인 1개 타일 (펼쳐진 상품 카드 내부).
///
/// 표시: 주문/수동 배지, 주문번호(externalOrderId), `필요 N (자동 a + 수동 m) · 구매 p`,
/// 구매기록 목록(음수는 빨강). 인라인 폼 2개:
///  - 구매기록: 날짜(date picker) + 수량(정수, 0 불가, 음수 허용) → [onRecordPurchase]
///  - 수동수량 교체: 정수(0+) → [onAdjustManual]
///
/// [busy]가 true면(조회/재적재/액션 진행 중) 폼 버튼을 비활성화한다.
class PurchaseLineTile extends StatefulWidget {
  final PurchaseLine line;
  final bool busy;

  /// 읽기전용(완료 탭)이면 인라인 폼을 숨기고 기록만 표시한다.
  final bool readOnly;
  final void Function(int itemId, String purchasedOn, int quantity)
      onRecordPurchase;
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
  DateTime _purchasedOn = DateTime.now();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manualController.text = widget.line.manualQty.toString();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _manualController.dispose();
    super.dispose();
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
    final dateStr = DateFormat('yyyy-MM-dd').format(_purchasedOn);
    widget.onRecordPurchase(widget.line.itemId, dateStr, qty);
    _qtyController.clear();
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
                child: Text(
                  '· ${r.purchasedOn}  ${r.quantity > 0 ? '+' : ''}${r.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: r.quantity < 0 ? Colors.red : Colors.grey[700],
                  ),
                ),
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
            const SizedBox(height: 8),

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
