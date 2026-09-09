import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/outbound_order.dart';

/// 출고 확인 카드 — 주문 라인 1건 + 소진할 물품 줄.
///
/// **규칙** (PLAN 2609_28 D11·D12):
/// - 진입은 **주문에서만** 한다 — 물품 검색으로 시작하는 UI 를 붙이지 않는다
/// - 물품 줄마다 [확인] 버튼이 따로 있고 **1건마다 서버 호출** 한다(일괄 전송 금지)
/// - 기본 수량 = `필요 − 확인`
///
/// [inProgressProductId] 가 그 줄의 물품이면 버튼 자리에 스피너를 띄운다.
class OutboundOrderCard extends StatefulWidget {
  final OutboundOrder order;
  final int? inProgressProductId;
  final bool busy;
  final void Function(int productId, int quantity) onConfirm;

  const OutboundOrderCard({
    required this.order,
    required this.onConfirm,
    this.inProgressProductId,
    this.busy = false,
    super.key,
  });

  @override
  State<OutboundOrderCard> createState() => _OutboundOrderCardState();
}

class _OutboundOrderCardState extends State<OutboundOrderCard> {
  /// 물품별 수량 컨트롤러. 확인 후 남은 수량으로 되돌린다.
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(OutboundProductLine line) {
    final existing = _controllers[line.productId];
    if (existing != null) return existing;
    final created =
        TextEditingController(text: '${line.remainingQty > 0 ? line.remainingQty : 0}');
    _controllers[line.productId] = created;
    return created;
  }

  @override
  void didUpdateWidget(covariant OutboundOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 확인 성공으로 남은 수량이 바뀌면 입력값을 새 남은 수량으로 맞춘다.
    for (final line in widget.order.products) {
      final controller = _controllers[line.productId];
      if (controller == null) continue;
      final previous = oldWidget.order.products
          .where((p) => p.productId == line.productId)
          .toList();
      if (previous.isEmpty) continue;
      if (previous.first.confirmedQty != line.confirmedQty) {
        controller.text = '${line.remainingQty > 0 ? line.remainingQty : 0}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.externalOrderId,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${order.itemName} · ${order.orderQty}개',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (order.sellerName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  order.sellerName,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            const Divider(height: 16),
            ...order.products.map(_buildProductRow),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(OutboundProductLine line) {
    final controller = _controllerFor(line);
    final inProgress = widget.inProgressProductId == line.productId;
    final done = line.remainingQty <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.productName,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '필요 ${line.requiredQty}  확인 ${line.confirmedQty}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: controller,
                  enabled: !done && !widget.busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const Spacer(),
              if (inProgress)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ElevatedButton(
                  onPressed: done || widget.busy
                      ? null
                      : () => _confirm(line, controller),
                  child: const Text('확인'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm(OutboundProductLine line, TextEditingController controller) {
    final quantity = int.tryParse(controller.text.trim()) ?? 0;
    if (quantity <= 0) {
      _toast('수량은 1 이상이어야 합니다.');
      return;
    }
    if (quantity > line.remainingQty) {
      _toast('남은 출고 수량(${line.remainingQty})을 초과했습니다.');
      return;
    }
    widget.onConfirm(line.productId, quantity);
  }

  /// 하단 내비가 오버레이라 floating + bottom:70 이 필수다.
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
}
