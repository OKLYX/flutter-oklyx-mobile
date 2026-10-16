import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_event.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_state.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../data/models/elevenst_delivery_line.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/elevenst_order_action_bloc.dart';
import '../bloc/elevenst_order_action_event.dart';
import '../bloc/elevenst_order_action_state.dart';

/// Today + [days] as 'yyyy-MM-dd' in KST — 11st reads every date in KST (D32).
String _kstDatePlus(int days) {
  final day = DateTime.now().toUtc().add(const Duration(hours: 9));
  final date = DateTime.utc(day.year, day.month, day.day + days);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// EUC-KR byte length as 11st counts it: ASCII 1 byte, anything else 2 bytes.
int _eucKrBytes(String text) =>
    text.runes.fold(0, (sum, rune) => sum + (rune < 0x80 ? 1 : 2));

/// [주문 취소] of an 11st line — sale refusal 1638 of the **whole line**
/// (FEATURE_2610_17 / D61).
///
/// **Purpose**: the cancel tab of an 11st order. Input = one of the six reasons
/// (11st's own names, `ElevenstOrderActionState.choices.cancelReasons`) + the
/// reason text (1~200 characters).
/// **File**: lib/features/order/presentation/widgets/elevenst_seller_action_sections.dart
///
/// **Usage** (under the `ElevenstOrderActionBloc` provider of the order detail):
/// ```dart
/// ElevenstSaleRefusalSection(order: order)
/// ```
///
/// ⚠️ The line does not change here — the next sync shows it as cancelled
/// (D14); the success toast says so.
/// ⚠️ Irreversible → the confirm carries the buyer-consent line and, for any
/// reason other than 10 「고객변심」, the seller-score line.
/// ❌ Not for Coupang lines — Coupang keeps the quantity cancel section.
class ElevenstSaleRefusalSection extends StatefulWidget {
  final OrderItem order;

  const ElevenstSaleRefusalSection({super.key, required this.order});

  @override
  State<ElevenstSaleRefusalSection> createState() =>
      _ElevenstSaleRefusalSectionState();
}

class _ElevenstSaleRefusalSectionState
    extends State<ElevenstSaleRefusalSection> {
  static const int _maxReasonLength = 200;
  static const String _customerChange = '10';
  static const String _sentMessage = '11번가에 취소를 보냈습니다. 다음 동기화 뒤 취소로 표시됩니다.';

  final TextEditingController _textController = TextEditingController();
  String? _reasonCode;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<ElevenstOrderActionBloc>();
    final reasonCode = _reasonCode;
    if (reasonCode == null) return;
    final lines = [
      '구매자 동의를 받은 뒤 진행하세요.',
      '이 주문 줄 전체(${widget.order.orderCount}개)를 11번가에서 취소합니다. 되돌릴 수 없습니다.',
      if (reasonCode != _customerChange)
        '판매자 사유 취소는 11번가 판매자 신용점수가 1점 깎일 수 있습니다.',
    ];
    final ok = await showAppConfirmDialog(
      context,
      title: '주문 취소',
      message: lines.join('\n'),
      confirmText: '주문 취소',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) return;
    bloc.add(ElevenstSaleRefusalRequested(
      orderItemId: widget.order.id,
      quantity: widget.order.purchasableQty,
      reasonCode: reasonCode,
      reasonText: _textController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ElevenstOrderActionBloc, ElevenstOrderActionState>(
      listenWhen: (p, c) =>
          c.saleRefusal != null && c.saleRefusal != p.saleRefusal,
      listener: (context, state) {
        final refusal = state.saleRefusal!;
        if (refusal.cancelled.isNotEmpty) {
          showSuccessToast(context, _sentMessage);
        } else if (refusal.failed.isNotEmpty) {
          // 11st's own code and wording, as given (D61).
          final failed = refusal.failed.first;
          showErrorToast(context, '${failed.code}: ${failed.message}');
        } else if (refusal.skipped.isNotEmpty &&
            refusal.skipped.first.reason != null) {
          showNoticeToast(context, refusal.skipped.first.reason!);
        }
      },
      builder: (context, state) {
        if (state.forbidden) return const SizedBox.shrink();
        final sent = state.saleRefusal?.cancelled.isNotEmpty ?? false;
        final locked = state.sending || sent;
        final text = _textController.text.trim();
        final ready = !locked &&
            _reasonCode != null &&
            text.isNotEmpty &&
            text.length <= _maxReasonLength &&
            widget.order.purchasableQty > 0;
        final reasons = state.choices.cancelReasons;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: reasons.any((r) => r.code == _reasonCode)
                    ? _reasonCode
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '취소 사유'),
                items: reasons
                    .map((r) => DropdownMenuItem<String>(
                          value: r.code,
                          child: Text(r.label, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: locked
                    ? null
                    : (value) => setState(() => _reasonCode = value),
              ),
              if (state.choicesFailed)
                Text(
                  '사유 목록을 불러오지 못했습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLength: _maxReasonLength,
                maxLines: 3,
                enabled: !locked,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: '사유 글 (1~200자)'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: ready ? () => _confirm(context) : null,
                child: state.sending
                    ? const AppBusyLabel('주문 취소')
                    : const Text('주문 취소'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [발송지연 안내] of an 11st delivery — 6728 (FEATURE_2610_17 / D63).
///
/// **Purpose**: under the shipment tab of a paid / preparing 11st order. Sends
/// the expected date (tomorrow ~ today + 30, KST), one of the five reasons and
/// the detail text; 11st tells the buyer by e-mail and SMS.
///
/// **Usage**: `ElevenstDeliveryDelaySection(order: order)`
///
/// ⚠️ The detail text is 20~300 EUC-KR bytes on 11st (−28307) — counted the
/// same way here (non-ASCII = 2) and blocked with
/// 「상세 사유는 한글 10~150자로 적어 주세요.」.
/// ⚠️ Sending again to the same delivery is not blocked (D63).
class ElevenstDeliveryDelaySection extends StatefulWidget {
  final OrderItem order;

  const ElevenstDeliveryDelaySection({super.key, required this.order});

  @override
  State<ElevenstDeliveryDelaySection> createState() =>
      _ElevenstDeliveryDelaySectionState();
}

class _ElevenstDeliveryDelaySectionState
    extends State<ElevenstDeliveryDelaySection> {
  static const int _minBytes = 20;
  static const int _maxBytes = 300;
  static const int _maxDays = 30;
  static const String _bytesMessage = '상세 사유는 한글 10~150자로 적어 주세요.';

  final TextEditingController _textController = TextEditingController();
  bool _open = false;
  String? _expectedDate;
  String? _reasonCode;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final first = DateTime.parse(_kstDatePlus(1));
    final last = DateTime.parse(_kstDatePlus(_maxDays));
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(() => _expectedDate =
        '${picked.year}-${two(picked.month)}-${two(picked.day)}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ElevenstOrderActionBloc, ElevenstOrderActionState>(
      listenWhen: (p, c) => c.delaySent && !p.delaySent,
      listener: (context, state) =>
          showSuccessToast(context, '발송지연 안내를 보냈습니다.'),
      builder: (context, state) {
        if (state.forbidden) return const SizedBox.shrink();
        final text = _textController.text.trim();
        final bytes = _eucKrBytes(text);
        final bytesInvalid =
            text.isNotEmpty && (bytes < _minBytes || bytes > _maxBytes);
        final ready = !state.sending &&
            _expectedDate != null &&
            _reasonCode != null &&
            text.isNotEmpty &&
            !bytesInvalid;
        final hint = TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
        final reasons = state.choices.delayReasons;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: state.sending
                      ? null
                      : () => setState(() => _open = !_open),
                  child: const Text('발송지연 안내'),
                ),
                if (_open) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: state.sending ? null : () => _pickDate(context),
                    child: Text('예상 발송일 ${_expectedDate ?? '-'}'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: reasons.any((r) => r.code == _reasonCode)
                        ? _reasonCode
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '지연 사유'),
                    items: reasons
                        .map((r) => DropdownMenuItem<String>(
                              value: r.code,
                              child: Text(r.label,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: state.sending
                        ? null
                        : (value) => setState(() => _reasonCode = value),
                  ),
                  if (state.choicesFailed)
                    Text('사유 목록을 불러오지 못했습니다.', style: hint),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    enabled: !state.sending,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: '상세 사유'),
                  ),
                  if (bytesInvalid)
                    Text(
                      _bytesMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '예상 발송일까지는 지연 불이익이 없지만, 예상 발송일이 지나면 불이익이 생길 수 있습니다.',
                    style: hint,
                  ),
                  Text('구매자에게 이메일 · 문자로 안내됩니다.', style: hint),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: ready
                        ? () => context
                            .read<ElevenstOrderActionBloc>()
                            .add(ElevenstDeliveryDelayRequested(
                              orderItemId: widget.order.id,
                              body: {
                                'expectedDate': _expectedDate,
                                'reasonCode': _reasonCode,
                                'reasonText': text,
                              },
                            ))
                        : null,
                    child: state.sending
                        ? const AppBusyLabel('보내기')
                        : const Text('보내기'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 「일부 줄만 보내기」 (1636) and 「한 줄을 송장 여러 장으로」 (6791) of an 11st
/// delivery in preparing (FEATURE_2610_17 / D64).
///
/// **Purpose**: shown in the shipment tab when the user picks one of the two
/// modes. Sends through `ManualShipmentBloc` (same endpoint, same carrier
/// choice and the same result lock as the one-invoice form) with the `mode` ·
/// `orderItemIds` · `splits` keys.
///
/// **Usage**: `ElevenstSplitShipmentSection(order: order, split: false)`
///
/// ⚠️ Partial: only lines still in preparing get a checkbox (none checked at
/// first); the delivery needs two or more lines; add-on lines alone are
/// blocked with 「추가구성 상품만 따로 보낼 수 없습니다.」; a confirm carries the
/// buyer-consent line.
/// ⚠️ Split: one line with quantity 2 or more; 2~10 invoice rows; the
/// quantities must add up to the order quantity.
class ElevenstSplitShipmentSection extends StatefulWidget {
  final OrderItem order;

  /// true = 「한 줄을 송장 여러 장으로」, false = 「일부 줄만 보내기」.
  final bool split;

  const ElevenstSplitShipmentSection(
      {super.key, required this.order, required this.split});

  @override
  State<ElevenstSplitShipmentSection> createState() =>
      _ElevenstSplitShipmentSectionState();
}

class _ElevenstSplitShipmentSectionState
    extends State<ElevenstSplitShipmentSection> {
  static const int _minSplits = 2;
  static const int _maxSplits = 10;

  final TextEditingController _invoiceController = TextEditingController();
  final List<TextEditingController> _rowInvoices = [];
  final List<TextEditingController> _rowQuantities = [];
  final Set<int> _checked = {};
  int? _splitLineId;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _minSplits; i++) {
      _addRow();
    }
    final bloc = context.read<ElevenstOrderActionBloc>();
    if (bloc.state.deliveryLines.isEmpty) {
      bloc.add(ElevenstDeliveryLinesRequested(widget.order.id));
    }
  }

  void _addRow() {
    _rowInvoices.add(TextEditingController());
    _rowQuantities.add(TextEditingController());
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    for (final c in [..._rowInvoices, ..._rowQuantities]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendPartial(BuildContext context, List<int> ids) async {
    final bloc = context.read<ManualShipmentBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '일부 줄만 보내기',
      message: '구매자 동의를 받은 뒤 보내세요. 고른 ${ids.length}줄만 발송처리되고 '
          '나머지는 배송준비중으로 남습니다.',
      confirmText: '발송처리',
    );
    if (!ok || bloc.isClosed) return;
    bloc.add(SubmitManualShipment(
      orderItemId: widget.order.id,
      invoiceNumber: _invoiceController.text.trim(),
      elevenst: {'mode': 'PARTIAL', 'orderItemIds': ids},
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
      builder: (context, manual) =>
          BlocBuilder<ElevenstOrderActionBloc, ElevenstOrderActionState>(
        builder: (context, state) {
          if (state.deliveryLinesFailed) {
            return Text(
              '주문 줄을 불러오지 못했습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }
          final locked = manual.submitting || manual.result != null;
          final open = state.deliveryLines
              .where((l) => l.status == OrderStatus.preparing)
              .toList();
          final carrier = DropdownButtonFormField<String>(
            value: manual.options
                    .any((o) => o.deliveryCompanyCode == manual.carrierCode)
                ? manual.carrierCode
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '택배사'),
            items: manual.options
                .map((o) => DropdownMenuItem<String>(
                      value: o.deliveryCompanyCode,
                      child:
                          Text(o.carrierName, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: locked
                ? null
                : (value) {
                    if (value != null) {
                      context
                          .read<ManualShipmentBloc>()
                          .add(CarrierSelected(value));
                    }
                  },
          );
          return widget.split
              ? _buildSplit(context, manual, open, carrier, locked)
              : _buildPartial(context, manual, state, open, carrier, locked);
        },
      ),
    );
  }

  Widget _buildPartial(
    BuildContext context,
    ManualShipmentState manual,
    ElevenstOrderActionState state,
    List<ElevenstDeliveryLine> open,
    Widget carrier,
    bool locked,
  ) {
    final needsTwo = state.deliveryLines.length < 2;
    final chosen = open.where((l) => _checked.contains(l.orderItemId)).toList();
    final addOnOnly = chosen.isNotEmpty && chosen.every((l) => l.addOn);
    final ready = !locked &&
        !needsTwo &&
        chosen.isNotEmpty &&
        !addOnOnly &&
        manual.carrierCode != null &&
        _invoiceController.text.trim().isNotEmpty;
    final hint = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (needsTwo && state.deliveryLines.isNotEmpty)
          Text('일부 줄만 보내기는 주문 줄이 2개 이상인 배송건에서만 할 수 있습니다', style: hint),
        for (final line in open)
          CheckboxListTile(
            value: _checked.contains(line.orderItemId),
            onChanged: locked || needsTwo
                ? null
                : (value) => setState(() => value == true
                    ? _checked.add(line.orderItemId)
                    : _checked.remove(line.orderItemId)),
            title: Text('${line.itemName ?? '-'} · ${line.orderQty}개'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        if (addOnOnly)
          Text(
            '추가구성 상품만 따로 보낼 수 없습니다.',
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        carrier,
        const SizedBox(height: 12),
        TextField(
          controller: _invoiceController,
          maxLength: 50,
          enabled: !locked,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: '송장번호'),
        ),
        FilledButton(
          onPressed: ready
              ? () => _sendPartial(
                  context, chosen.map((l) => l.orderItemId).toList())
              : null,
          child: manual.submitting
              ? const AppBusyLabel('발송처리')
              : const Text('발송처리'),
        ),
      ],
    );
  }

  Widget _buildSplit(
    BuildContext context,
    ManualShipmentState manual,
    List<ElevenstDeliveryLine> open,
    Widget carrier,
    bool locked,
  ) {
    final splittable = open.where((l) => l.orderQty >= 2).toList();
    final target =
        splittable.where((l) => l.orderItemId == _splitLineId).firstOrNull;
    final quantities =
        _rowQuantities.map((c) => int.tryParse(c.text.trim())).toList();
    final filled = List.generate(
        _rowInvoices.length,
        (i) =>
            _rowInvoices[i].text.trim().isNotEmpty &&
            (quantities[i] ?? 0) >= 1).every((ok) => ok);
    final sum = quantities.fold<int>(0, (total, q) => total + (q ?? 0));
    final sumInvalid = target != null && filled && sum != target.orderQty;
    final ready = !locked &&
        target != null &&
        manual.carrierCode != null &&
        filled &&
        !sumInvalid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in splittable)
          RadioListTile<int>(
            value: line.orderItemId,
            groupValue: _splitLineId,
            onChanged:
                locked ? null : (value) => setState(() => _splitLineId = value),
            title: Text('${line.itemName ?? '-'} · ${line.orderQty}개'),
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 12),
        carrier,
        for (var i = 0; i < _rowInvoices.length; i++)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rowInvoices[i],
                  maxLength: 50,
                  enabled: !locked,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: '송장번호'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _rowQuantities[i],
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: '수량'),
                ),
              ),
              if (_rowInvoices.length > _minSplits)
                TextButton(
                  onPressed: locked
                      ? null
                      : () => setState(() {
                            _rowInvoices.removeAt(i).dispose();
                            _rowQuantities.removeAt(i).dispose();
                          }),
                  child: const Text('삭제'),
                ),
            ],
          ),
        TextButton(
          onPressed: locked || _rowInvoices.length >= _maxSplits
              ? null
              : () => setState(_addRow),
          child: const Text('송장 줄 추가'),
        ),
        if (sumInvalid)
          Text(
            '송장별 수량의 합이 주문 수량(${target.orderQty}개)과 같아야 합니다.',
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: ready
              ? () {
                  final splits = [
                    for (var i = 0; i < _rowInvoices.length; i++)
                      {
                        'invoiceNumber': _rowInvoices[i].text.trim(),
                        'quantity': quantities[i],
                      },
                  ];
                  context.read<ManualShipmentBloc>().add(SubmitManualShipment(
                        orderItemId: widget.order.id,
                        invoiceNumber: splits.first['invoiceNumber'] as String,
                        elevenst: {
                          'mode': 'SPLIT',
                          'orderItemIds': [target.orderItemId],
                          'splits': splits,
                        },
                      ));
                }
              : null,
          child: manual.submitting
              ? const AppBusyLabel('발송처리')
              : const Text('발송처리'),
        ),
      ],
    );
  }
}

/// [방문수령 완료] of an 11st visit-pickup order — 7052 (FEATURE_2610_17 /
/// D66).
///
/// **Purpose**: the shipment tab shows it instead of the invoice form when the
/// buyer picks the goods up, from paid on. Sends the buyer's code (trimmed
/// only); 11st marks the order shipped and delivered at once.
///
/// **Usage**: `ElevenstVisitPickupSection(order: order)`
///
/// ⚠️ Irreversible → confirm
/// 「구매자가 상품을 받아 갔으면 완료하세요. 되돌릴 수 없습니다.」.
/// A wrong code toasts 11st's own wording.
class ElevenstVisitPickupSection extends StatefulWidget {
  final OrderItem order;

  const ElevenstVisitPickupSection({super.key, required this.order});

  @override
  State<ElevenstVisitPickupSection> createState() =>
      _ElevenstVisitPickupSectionState();
}

class _ElevenstVisitPickupSectionState
    extends State<ElevenstVisitPickupSection> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<ElevenstOrderActionBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '방문수령 완료',
      message: '구매자가 상품을 받아 갔으면 완료하세요. 되돌릴 수 없습니다.',
      confirmText: '방문수령 완료',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) return;
    bloc.add(ElevenstVisitPickupRequested(
        orderItemId: widget.order.id, certCode: _codeController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ElevenstOrderActionBloc, ElevenstOrderActionState>(
      listenWhen: (p, c) => c.visitPickupDone && !p.visitPickupDone,
      listener: (context, state) =>
          showSuccessToast(context, '방문수령 완료를 보냈습니다.'),
      builder: (context, state) {
        if (state.forbidden) return const SizedBox.shrink();
        final locked = state.sending || state.visitPickupDone;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _codeController,
                maxLength: 50,
                enabled: !locked,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: '방문수령 인증번호'),
              ),
              FilledButton(
                onPressed: !locked && _codeController.text.trim().isNotEmpty
                    ? () => _confirm(context)
                    : null,
                child: state.sending
                    ? const AppBusyLabel('방문수령 완료')
                    : const Text('방문수령 완료'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [입고완료 처리] of an 11st reserved-sale line — 1773 (FEATURE_2610_17 /
/// D67).
///
/// **Purpose**: takes the place of the order-confirmation section for a
/// reserved sale. After a success (or when the server says it was already
/// sent) it shows 「입고완료 보냄」; the raw status is left to the next sync.
///
/// **Usage**: `ElevenstStockConfirmSection(order: order)`
///
/// ⚠️ Irreversible → confirm
/// 「상품이 입고되어 발송 준비가 되었으면 처리하세요. 되돌릴 수 없습니다.」.
class ElevenstStockConfirmSection extends StatelessWidget {
  final OrderItem order;

  const ElevenstStockConfirmSection({super.key, required this.order});

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<ElevenstOrderActionBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '입고완료 처리',
      message: '상품이 입고되어 발송 준비가 되었으면 처리하세요. 되돌릴 수 없습니다.',
      confirmText: '입고완료 처리',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) return;
    bloc.add(ElevenstStockConfirmRequested(order.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ElevenstOrderActionBloc, ElevenstOrderActionState>(
      builder: (context, state) {
        if (state.forbidden || order.status != OrderStatus.paid) {
          return const SizedBox.shrink();
        }
        final sent = state.stockSent || order.stockConfirmSent;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '입고완료 처리',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (sent)
                const Text(
                  '입고완료 보냄',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.successForeground,
                  ),
                )
              else
                FilledButton(
                  onPressed: state.sending ? null : () => _confirm(context),
                  child: state.sending
                      ? const AppBusyLabel('입고완료 처리')
                      : const Text('입고완료 처리'),
                ),
            ],
          ),
        );
      },
    );
  }
}
