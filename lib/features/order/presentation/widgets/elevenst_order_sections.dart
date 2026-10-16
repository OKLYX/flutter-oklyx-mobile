import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_state.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../data/models/elevenst_cancel_request.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/elevenst_order_action_bloc.dart';
import '../bloc/elevenst_order_action_event.dart';
import '../bloc/elevenst_order_action_state.dart';

/// Today as 'yyyy-MM-dd' in KST — 11st reads every date in KST (D32).
String _kstToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 9));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

/// The 11st-only blocks of the order detail (FEATURE_2610_17 / D19 · D35 ·
/// D36 · D37 · D38 · D39 ⑤ · D40 · D41 · D62): 「취소 요청」 with [취소 승인] ·
/// [취소 거부] · [책임사유 오류로 거부], and [판매자가 대신 반품 신청].
///
/// **Purpose**: one entry point so the order detail page adds a single line
/// for 11st orders, and so the failures of all three writes toast in one place.
/// **File**: lib/features/order/presentation/widgets/elevenst_order_sections.dart
///
/// **Usage** (inside the order detail, under `ElevenstOrderActionBloc` and
/// `ManualShipmentBloc` providers — both are made only for 11st / market orders):
/// ```dart
/// if (isElevenst) ElevenstOrderSections(order: o),
/// ```
///
/// ⚠️ The carrier list is the one `ManualShipmentBloc` already loaded for the
/// 11st order — it is not loaded again here.
/// ⚠️ The write buttons hide on 403 (carrier list or a write) — mobile has no
/// role check of its own.
/// ⚠️ [판매자가 대신 반품 신청] shows only for a shipped line
/// (`SHIPPED` · `DELIVERING` · `DELIVERED`) that is not fully cancelled (D39 ⑤).
/// ❌ Do not show it for Coupang orders — Coupang cancel requests and seller
/// returns are not handled here (D19 · D35).
class ElevenstOrderSections extends StatelessWidget {
  final OrderItem order;

  const ElevenstOrderSections({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ElevenstOrderActionBloc, ElevenstOrderActionState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && c.errorMessage != p.errorMessage,
      listener: (context, state) {
        showErrorToast(context, state.errorMessage!);
        context
            .read<ElevenstOrderActionBloc>()
            .add(const ElevenstActionErrorCleared());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CancelRequestsSection(order: order),
          if (isAlreadyShipped(order.status) && !order.cancelled)
            _SellerReturnSection(order: order),
        ],
      ),
    );
  }
}

/// 「취소 요청」 — the open requests of the line; draws nothing when there is
/// none (most orders). The reason is the server's 「사유 이름 — 사유 글」 (D41).
/// [책임사유 오류로 거부] shows where the server says `faultRejectable` (D62)
/// and shares the carrier · invoice · date inputs with [취소 거부].
class _CancelRequestsSection extends StatefulWidget {
  final OrderItem order;

  const _CancelRequestsSection({required this.order});

  @override
  State<_CancelRequestsSection> createState() => _CancelRequestsSectionState();
}

class _CancelRequestsSectionState extends State<_CancelRequestsSection> {
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _refuseTextController = TextEditingController();
  int? _rejectTargetId;
  int? _faultTargetId;
  bool _rejectSent = false;
  String? _carrierCode;
  String? _refuseCode;
  String _sendDate = _kstToday();

  @override
  void dispose() {
    _invoiceController.dispose();
    _refuseTextController.dispose();
    super.dispose();
  }

  Future<void> _confirmRejectFault(
      BuildContext context, ElevenstCancelRequest request) async {
    final bloc = context.read<ElevenstOrderActionBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '책임사유 오류로 거부',
      message: '이 취소 요청을 거부합니다. 구매자에게 사유가 전달되며 되돌릴 수 없습니다.',
      confirmText: '책임사유 오류로 거부',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) return;
    _rejectSent = true;
    bloc.add(ElevenstCancelFaultRejectRequested(
      requestId: request.id,
      orderItemId: widget.order.id,
      body: {
        'refuseCode': _refuseCode,
        'reasonText': _refuseTextController.text.trim(),
        'deliveryCompanyCode': _carrierCode,
        'invoiceNumber': _invoiceController.text.trim(),
        'sendDate': _sendDate,
      },
    ));
  }

  Future<void> _confirmApprove(
      BuildContext context, ElevenstCancelRequest request) async {
    final bloc = context.read<ElevenstOrderActionBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '취소 승인',
      message: '이 주문 줄의 취소 요청 ${request.quantity}개를 승인합니다. '
          '11번가에서 바로 취소 · 환불되며 되돌릴 수 없습니다.',
      confirmText: '취소 승인',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) return;
    bloc.add(ElevenstCancelApproveRequested(
        requestId: request.id, orderItemId: widget.order.id));
  }

  Future<void> _pickDate(BuildContext context) async {
    final initial = DateTime.tryParse(_sendDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 1),
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    setState(() =>
        _sendDate = '${picked.year}-${two(picked.month)}-${two(picked.day)}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ElevenstOrderActionBloc, ElevenstOrderActionState>(
      // A reject 11st accepted — close the form. Failures toast in
      // [ElevenstOrderSections]; the form stays open with its input.
      listenWhen: (p, c) =>
          _rejectSent && p.sending && !c.sending && c.errorMessage == null,
      listener: (context, state) {
        _invoiceController.clear();
        _refuseTextController.clear();
        setState(() {
          _rejectSent = false;
          _rejectTargetId = null;
          _faultTargetId = null;
          _carrierCode = null;
          _refuseCode = null;
        });
      },
      builder: (context, state) {
        if (state.requests.isEmpty && !state.requestsFailed) {
          return const SizedBox.shrink();
        }
        return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
          builder: (context, manual) {
            final canWrite = !manual.optionsForbidden && !state.forbidden;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '취소 요청',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (state.requestsFailed) ...[
                      const SizedBox(height: 8),
                      Text(
                        '취소 요청을 불러오지 못했습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    for (final request in state.requests)
                      _buildRequest(context, state, manual, request, canWrite),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequest(
    BuildContext context,
    ElevenstOrderActionState state,
    ManualShipmentState manual,
    ElevenstCancelRequest request,
    bool canWrite,
  ) {
    final rejecting = _rejectTargetId == request.id;
    final faultRejecting = _faultTargetId == request.id;
    final canSendReject = !state.sending &&
        _carrierCode != null &&
        _invoiceController.text.trim().isNotEmpty;
    final refuseText = _refuseTextController.text.trim();
    final canSendFault = canSendReject &&
        _refuseCode != null &&
        refuseText.isNotEmpty &&
        refuseText.length <= 200;
    final faultReasons = state.choices.faultRejectReasons;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${request.quantity}개 · ${request.reason}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            formatOrderDateTime(request.requestedAt),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: state.sending
                      ? null
                      : () => _confirmApprove(context, request),
                  child: const Text('취소 승인'),
                ),
                OutlinedButton(
                  onPressed: state.sending
                      ? null
                      : () => setState(() {
                            _faultTargetId = null;
                            _rejectTargetId = rejecting ? null : request.id;
                          }),
                  child: const Text('취소 거부'),
                ),
                if (request.faultRejectable)
                  OutlinedButton(
                    onPressed: state.sending
                        ? null
                        : () => setState(() {
                              _rejectTargetId = null;
                              _faultTargetId =
                                  faultRejecting ? null : request.id;
                            }),
                    child: const Text('책임사유 오류로 거부'),
                  ),
              ],
            ),
          ],
          if (canWrite && faultRejecting) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: faultReasons.any((r) => r.code == _refuseCode)
                  ? _refuseCode
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '거부 사유'),
              items: faultReasons
                  .map((r) => DropdownMenuItem<String>(
                        value: r.code,
                        child: Text(r.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: state.sending
                  ? null
                  : (value) => setState(() => _refuseCode = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _refuseTextController,
              maxLength: 200,
              maxLines: 3,
              enabled: !state.sending,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '사유 글 (1~200자)'),
            ),
          ],
          if (canWrite && (rejecting || faultRejecting)) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: manual.options
                      .any((o) => o.deliveryCompanyCode == _carrierCode)
                  ? _carrierCode
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '택배사'),
              items: manual.options
                  .map((o) => DropdownMenuItem<String>(
                        value: o.deliveryCompanyCode,
                        child: Text(o.carrierName,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: state.sending
                  ? null
                  : (value) => setState(() => _carrierCode = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _invoiceController,
              maxLength: 50,
              enabled: !state.sending,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '송장번호'),
            ),
            OutlinedButton(
              onPressed: state.sending ? null : () => _pickDate(context),
              child: Text('보낸 날짜 $_sendDate'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: faultRejecting
                  ? (canSendFault
                      ? () => _confirmRejectFault(context, request)
                      : null)
                  : (canSendReject
                      ? () {
                          _rejectSent = true;
                          context
                              .read<ElevenstOrderActionBloc>()
                              .add(ElevenstCancelRejectRequested(
                                requestId: request.id,
                                orderItemId: widget.order.id,
                                deliveryCompanyCode: _carrierCode!,
                                invoiceNumber: _invoiceController.text.trim(),
                                sendDate: _sendDate,
                              ));
                        }
                      : null),
              child: state.sending
                  ? AppBusyLabel(faultRejecting ? '책임사유 오류로 거부' : '취소 거부')
                  : Text(faultRejecting ? '책임사유 오류로 거부' : '취소 거부'),
            ),
          ],
        ],
      ),
    );
  }
}

/// [판매자가 대신 반품 신청] (API 1653) — the whole line quantity is returned;
/// carrier and invoice go together or not at all (D39 ⑤);
/// 「신청하면서 바로 반품완료」 asks once more (D36). No claim number comes
/// back — the claim shows up after the next sync.
class _SellerReturnSection extends StatefulWidget {
  final OrderItem order;

  const _SellerReturnSection({required this.order});

  @override
  State<_SellerReturnSection> createState() => _SellerReturnSectionState();
}

class _SellerReturnSectionState extends State<_SellerReturnSection> {
  static const int _maxReasonLength = 200;
  static const String _togetherMessage = '택배사와 송장번호를 함께 넣어 주세요.';
  static const String _sentMessage = '반품 신청을 보냈습니다. 반품/교환 화면에는 다음 동기화 뒤 나타납니다.';
  static const String _completeNowConfirm =
      '반품완료로 처리하면 11번가에서 바로 환불되며 되돌릴 수 없습니다. 계속할까요?';

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController();
  bool _open = false;
  String? _reasonCode;
  String? _feeMethod;
  String? _carrierCode;
  bool _completeNow = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _toggleOpen(BuildContext context, ElevenstOrderActionState state) {
    setState(() => _open = !_open);
    if (_open && state.reasons.isEmpty) {
      context
          .read<ElevenstOrderActionBloc>()
          .add(const ElevenstReturnReasonsRequested());
    }
  }

  Future<void> _submit(BuildContext context) async {
    final hasCarrier = _carrierCode != null;
    final hasInvoice = _invoiceController.text.trim().isNotEmpty;
    if (hasCarrier != hasInvoice) {
      showInputNoticeToast(context, _togetherMessage);
      return;
    }
    final bloc = context.read<ElevenstOrderActionBloc>();
    if (_completeNow) {
      final ok = await showAppConfirmDialog(
        context,
        title: '바로 반품완료',
        message: _completeNowConfirm,
        confirmText: '신청',
        isDangerous: true,
      );
      if (!ok || bloc.isClosed) return;
    }
    bloc.add(ElevenstReturnRequested(
      orderItemId: widget.order.id,
      body: {
        'reasonCode': _reasonCode,
        'reasonText': _reasonController.text.trim(),
        'shippingFeeMethod': _feeMethod,
        'completeNow': _completeNow,
        if (hasCarrier) 'deliveryCompanyCode': _carrierCode,
        if (hasCarrier) 'invoiceNumber': _invoiceController.text.trim(),
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
      builder: (context, manual) =>
          BlocBuilder<ElevenstOrderActionBloc, ElevenstOrderActionState>(
        builder: (context, state) {
          if (manual.optionsForbidden || state.forbidden) {
            return const SizedBox.shrink();
          }
          final locked = state.sending || state.returnSent;
          final text = _reasonController.text.trim();
          final ready = !locked &&
              _reasonCode != null &&
              text.isNotEmpty &&
              text.length <= _maxReasonLength &&
              _feeMethod != null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: state.sending
                        ? null
                        : () => _toggleOpen(context, state),
                    child: const Text('판매자가 대신 반품 신청'),
                  ),
                  if (_open)
                    ..._buildForm(context, state, manual, locked, ready),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildForm(
    BuildContext context,
    ElevenstOrderActionState state,
    ManualShipmentState manual,
    bool locked,
    bool ready,
  ) {
    final hint = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return [
      const SizedBox(height: 12),
      Text(
        '구매자의 동의를 받은 뒤 신청하세요. '
        '이 주문 줄의 전체 수량(${widget.order.orderCount}개)이 반품됩니다.',
        style: const TextStyle(fontSize: 13),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: state.reasons.any((r) => r.code == _reasonCode)
            ? _reasonCode
            : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: '반품 사유'),
        items: state.reasons
            .map((r) => DropdownMenuItem<String>(
                  value: r.code,
                  child: Text(r.label, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged:
            locked ? null : (value) => setState(() => _reasonCode = value),
      ),
      if (state.reasonsFailed) Text('사유 목록을 불러오지 못했습니다.', style: hint),
      const SizedBox(height: 12),
      TextField(
        controller: _reasonController,
        maxLength: _maxReasonLength,
        maxLines: 3,
        enabled: !locked,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: '사유 글 (1~200자)'),
      ),
      const Text('반품 배송비 전달', style: TextStyle(fontSize: 13)),
      RadioListTile<String>(
        value: '03',
        groupValue: _feeMethod,
        onChanged:
            locked ? null : (value) => setState(() => _feeMethod = value),
        title: const Text('박스에 동봉'),
        contentPadding: EdgeInsets.zero,
      ),
      RadioListTile<String>(
        value: '04',
        groupValue: _feeMethod,
        onChanged:
            locked ? null : (value) => setState(() => _feeMethod = value),
        title: const Text('판매자에게 직접 송금'),
        contentPadding: EdgeInsets.zero,
      ),
      DropdownButtonFormField<String?>(
        value: manual.options.any((o) => o.deliveryCompanyCode == _carrierCode)
            ? _carrierCode
            : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: '회수 택배사'),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('선택 안 함')),
          ...manual.options.map((o) => DropdownMenuItem<String?>(
                value: o.deliveryCompanyCode,
                child: Text(o.carrierName, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged:
            locked ? null : (value) => setState(() => _carrierCode = value),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _invoiceController,
        maxLength: 50,
        enabled: !locked,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: '회수 송장번호'),
      ),
      RadioListTile<bool>(
        value: false,
        groupValue: _completeNow,
        onChanged:
            locked ? null : (value) => setState(() => _completeNow = false),
        title: const Text('신청만'),
        contentPadding: EdgeInsets.zero,
      ),
      RadioListTile<bool>(
        value: true,
        groupValue: _completeNow,
        onChanged:
            locked ? null : (value) => setState(() => _completeNow = true),
        title: const Text('신청하면서 바로 반품완료'),
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: ready ? () => _submit(context) : null,
        child: state.sending ? const AppBusyLabel('신청') : const Text('신청'),
      ),
      if (state.returnSent) ...[
        const SizedBox(height: 8),
        const Text(
          _sentMessage,
          style: TextStyle(fontSize: 13, color: AppColors.successForeground),
        ),
      ],
    ];
  }
}
