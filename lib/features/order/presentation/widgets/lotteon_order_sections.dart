import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import '../../../shipping_label/presentation/bloc/manual_shipment_bloc.dart';
import '../../../shipping_label/presentation/bloc/manual_shipment_state.dart';
import '../../data/models/cancel_reason_option.dart';
import '../../data/models/lotteon_cancel_request.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/lotteon_order_action_bloc.dart';
import '../bloc/lotteon_order_action_event.dart';
import '../bloc/lotteon_order_action_state.dart';

/// The one LotteON code the screen keeps: 「제작지연」 needs a detail reason
/// (§3-4 contract value, FEATURE_2611_23 / D26).
const String _lotteonMakingDelayCode = 'PD_DL';

/// Gray helper text style of the LotteON sections.
TextStyle _hintStyle(BuildContext context) => TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

/// A reason dropdown fed by the server list (D58 — no code map in the app).
Widget _reasonDropdown({
  required String label,
  required List<CancelReasonOption> reasons,
  required String? value,
  required ValueChanged<String?>? onChanged,
}) =>
    DropdownButtonFormField<String>(
      initialValue: reasons.any((r) => r.code == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: reasons
          .map((r) => DropdownMenuItem<String>(
                value: r.code,
                child: Text(r.label, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );

/// Red filled button style of the irreversible LotteON writes.
ButtonStyle _dangerStyle(BuildContext context) => FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
    );

/// The LotteON-only blocks of the order detail above the tabs
/// (FEATURE_2611_23 / D24 · R54): 「취소 요청」 with [취소 승인] · [취소 거부].
///
/// **Purpose**: one entry point so the order detail page adds a single line
/// for LotteON orders, and so the failures of every LotteON write toast in
/// one place.
/// **File**:
/// lib/features/order/presentation/widgets/lotteon_order_sections.dart
///
/// **Usage** (inside the order detail, under `LotteonOrderActionBloc` and
/// `ManualShipmentBloc` providers — both are made for LotteON orders):
/// ```dart
/// if (isLotteon) LotteonOrderSections(order: o),
/// ```
///
/// ⚠️ The write buttons hide on 403 (carrier list or a write) — mobile has no
/// role check of its own.
/// ⚠️ The input state lives in `ValueNotifier`s, not in `setState` (R57).
/// ❌ Do not show it for Coupang · 11st orders — they have their own sections.
class LotteonOrderSections extends StatelessWidget {
  final OrderItem order;

  const LotteonOrderSections({required this.order, super.key});

  @override
  Widget build(BuildContext context) =>
      BlocListener<LotteonOrderActionBloc, LotteonOrderActionState>(
        listenWhen: (p, c) =>
            c.errorMessage != null && c.errorMessage != p.errorMessage,
        listener: (context, state) {
          showErrorToast(context, state.errorMessage!);
          context
              .read<LotteonOrderActionBloc>()
              .add(const LotteonActionErrorCleared());
        },
        child: _LotteonCancelRequestsSection(order: order),
      );
}

/// 「취소 요청」 — the open requests of the line; draws nothing when there is
/// none and the load did not fail (R54). The reason is the server's
/// 「사유 이름 — 사유 글」 (D71).
class _LotteonCancelRequestsSection extends StatefulWidget {
  final OrderItem order;

  const _LotteonCancelRequestsSection({required this.order});

  @override
  State<_LotteonCancelRequestsSection> createState() =>
      _LotteonCancelRequestsSectionState();
}

class _LotteonCancelRequestsSectionState
    extends State<_LotteonCancelRequestsSection> {
  final TextEditingController _textController = TextEditingController();
  final ValueNotifier<int?> _rejectTarget = ValueNotifier<int?>(null);
  final ValueNotifier<String?> _reasonCode = ValueNotifier<String?>(null);
  bool _rejectSent = false;

  @override
  void dispose() {
    _textController.dispose();
    _rejectTarget.dispose();
    _reasonCode.dispose();
    super.dispose();
  }

  Future<void> _confirmApprove(
      BuildContext context, LotteonCancelRequest request) async {
    final bloc = context.read<LotteonOrderActionBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '취소 승인',
      // ignore: lines_longer_than_80_chars
      message: '이 주문 줄의 취소 요청 ${request.quantity}개를 승인합니다. 롯데ON 에서 바로 취소 · 환불되며 되돌릴 수 없습니다.',
      confirmText: '취소 승인',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) {
      return;
    }
    bloc.add(LotteonCancelApproveRequested(
        requestId: request.id, orderItemId: widget.order.id));
  }

  void _toggleReject(int requestId) {
    _rejectTarget.value = _rejectTarget.value == requestId ? null : requestId;
  }

  void _sendReject(BuildContext context, LotteonCancelRequest request) {
    final code = _reasonCode.value;
    if (code == null) {
      return;
    }
    _rejectSent = true;
    context.read<LotteonOrderActionBloc>().add(LotteonCancelRejectRequested(
          requestId: request.id,
          orderItemId: widget.order.id,
          reasonCode: code,
          reasonText: _textController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<LotteonOrderActionBloc, LotteonOrderActionState>(
        // A reject LotteON accepted — close the form. Failures toast in
        // [LotteonOrderSections]; the form stays open with its input.
        listenWhen: (p, c) =>
            _rejectSent && p.sending && !c.sending && c.errorMessage == null,
        listener: (context, state) {
          _rejectSent = false;
          _textController.clear();
          _reasonCode.value = null;
          _rejectTarget.value = null;
        },
        child: BlocBuilder<LotteonOrderActionBloc, LotteonOrderActionState>(
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (state.requestsFailed) ...[
                          const SizedBox(height: 8),
                          Text(
                            '취소 요청을 불러오지 못했습니다.',
                            style: _hintStyle(context),
                          ),
                        ],
                        for (final request in state.requests)
                          _buildRequest(context, state, request, canWrite),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  Widget _buildRequest(
    BuildContext context,
    LotteonOrderActionState state,
    LotteonCancelRequest request,
    bool canWrite,
  ) =>
      Padding(
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
              style: _hintStyle(context),
            ),
            if (canWrite) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    style: _dangerStyle(context),
                    onPressed: state.sending
                        ? null
                        : () => _confirmApprove(context, request),
                    child: const Text('취소 승인'),
                  ),
                  OutlinedButton(
                    onPressed:
                        state.sending ? null : () => _toggleReject(request.id),
                    child: const Text('취소 거부'),
                  ),
                ],
              ),
              ListenableBuilder(
                listenable: Listenable.merge([_rejectTarget, _reasonCode]),
                builder: (context, _) {
                  if (_rejectTarget.value != request.id) {
                    return const SizedBox.shrink();
                  }
                  return _buildRejectForm(context, state, request);
                },
              ),
            ],
          ],
        ),
      );

  /// [취소 거부] form under the request — reason + optional text, no confirm
  /// (R54).
  Widget _buildRejectForm(
    BuildContext context,
    LotteonOrderActionState state,
    LotteonCancelRequest request,
  ) {
    final ready = !state.sending && _reasonCode.value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _reasonDropdown(
          label: '거부 사유',
          reasons: state.choices.cancelRejectReasons,
          value: _reasonCode.value,
          onChanged:
              state.sending ? null : (value) => _reasonCode.value = value,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          maxLength: 200,
          maxLines: 3,
          enabled: !state.sending,
          decoration: const InputDecoration(labelText: '사유 글 (선택, 200자까지)'),
        ),
        FilledButton(
          style: _dangerStyle(context),
          onPressed: ready ? () => _sendReject(context, request) : null,
          child:
              state.sending ? const AppBusyLabel('취소 거부') : const Text('취소 거부'),
        ),
      ],
    );
  }
}

/// [주문 취소] of a LotteON line — seller cancel 225 of the **whole line**
/// (FEATURE_2611_23 / D25 · D57 · R53).
///
/// **Purpose**: the cancel tab of a LotteON order. Input = one of the five
/// reasons (LotteON's own names, `LotteonOrderActionState.choices`) + the
/// optional reason text (up to 200 characters).
/// **File**:
/// lib/features/order/presentation/widgets/lotteon_order_sections.dart
///
/// **Usage** (under the `LotteonOrderActionBloc` provider of the order
/// detail):
/// ```dart
/// LotteonSellerCancelSection(order: order)
/// ```
///
/// ⚠️ The line does not change here — the next sync shows it as cancelled;
/// the success toast says so.
/// ⚠️ The sent quantity is the remaining quantity of the line — there is no
/// quantity input.
/// ❌ Not for Coupang lines (the quantity cancel section) or 11st lines (the
/// sale refusal section).
class LotteonSellerCancelSection extends StatefulWidget {
  final OrderItem order;

  const LotteonSellerCancelSection({required this.order, super.key});

  @override
  State<LotteonSellerCancelSection> createState() =>
      _LotteonSellerCancelSectionState();
}

class _LotteonSellerCancelSectionState
    extends State<LotteonSellerCancelSection> {
  final TextEditingController _textController = TextEditingController();
  final ValueNotifier<String?> _reasonCode = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _textController.dispose();
    _reasonCode.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    final bloc = context.read<LotteonOrderActionBloc>();
    final reasonCode = _reasonCode.value;
    if (reasonCode == null) {
      return;
    }
    final count = widget.order.orderCount;
    final ok = await showAppConfirmDialog(
      context,
      title: '주문 취소',
      message: '이 주문 줄 전체($count개)를 롯데ON 에서 취소합니다. 되돌릴 수 없습니다.',
      confirmText: '주문 취소',
      isDangerous: true,
    );
    if (!ok || bloc.isClosed) {
      return;
    }
    bloc.add(LotteonSellerCancelRequested(
      orderItemId: widget.order.id,
      quantity: widget.order.purchasableQty,
      reasonCode: reasonCode,
      reasonText: _textController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LotteonOrderActionBloc, LotteonOrderActionState>(
        listenWhen: (p, c) =>
            c.sellerCancel != null && c.sellerCancel != p.sellerCancel,
        listener: (context, state) {
          final result = state.sellerCancel!;
          if (result.cancelled.isNotEmpty) {
            showSuccessToast(
              context,
              '롯데ON 에 취소를 보냈습니다. 다음 동기화 뒤 취소로 표시됩니다.',
            );
          } else if (result.failed.isNotEmpty) {
            // LotteON's own code and wording, as given (R53).
            final failed = result.failed.first;
            showErrorToast(context, '${failed.code}: ${failed.message}');
          } else if (result.skipped.isNotEmpty &&
              result.skipped.first.reason != null) {
            showNoticeToast(context, result.skipped.first.reason!);
          }
        },
        builder: (context, state) {
          if (state.forbidden) {
            return const SizedBox.shrink();
          }
          final sent = state.sellerCancel?.cancelled.isNotEmpty ?? false;
          final locked = state.sending || sent;
          return AppCard(
            child: ValueListenableBuilder<String?>(
              valueListenable: _reasonCode,
              builder: (context, reasonCode, _) {
                final ready = !locked &&
                    reasonCode != null &&
                    widget.order.purchasableQty >= 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _reasonDropdown(
                      label: '취소 사유',
                      reasons: state.choices.cancelReasons,
                      value: reasonCode,
                      onChanged:
                          locked ? null : (value) => _reasonCode.value = value,
                    ),
                    if (state.choicesFailed)
                      Text('사유 목록을 불러오지 못했습니다.', style: _hintStyle(context)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLength: 200,
                      maxLines: 3,
                      enabled: !locked,
                      decoration:
                          const InputDecoration(labelText: '사유 글 (선택, 200자까지)'),
                    ),
                    FilledButton(
                      style: _dangerStyle(context),
                      onPressed: ready ? () => _confirm(context) : null,
                      child: state.sending
                          ? const AppBusyLabel('주문 취소')
                          : const Text('주문 취소'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
}

/// [발송 약정일 안내] of a LotteON order — 138 (FEATURE_2611_23 / D26 · R55).
///
/// **Purpose**: under the shipment tab of a paid / preparing LotteON order.
/// Sends the appointment date, one of the four reasons and — for
/// 「제작지연」 — one of the two detail reasons; the server sends it for every
/// line of the order.
/// **File**:
/// lib/features/order/presentation/widgets/lotteon_order_sections.dart
///
/// **Usage**: `LotteonDeliveryAppointmentSection(order: order)`
///
/// ⚠️ The screen does not limit the date — LotteON answers a wrong one.
/// ⚠️ Sending again is not blocked.
/// ❌ No 11st delay-notice hint lines here.
class LotteonDeliveryAppointmentSection extends StatefulWidget {
  final OrderItem order;

  const LotteonDeliveryAppointmentSection({required this.order, super.key});

  @override
  State<LotteonDeliveryAppointmentSection> createState() =>
      _LotteonDeliveryAppointmentSectionState();
}

class _LotteonDeliveryAppointmentSectionState
    extends State<LotteonDeliveryAppointmentSection> {
  final ValueNotifier<bool> _open = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> _date = ValueNotifier<DateTime?>(null);
  final ValueNotifier<String?> _reasonCode = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _detailCode = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _open.dispose();
    _date.dispose();
    _reasonCode.dispose();
    _detailCode.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    _date.value = picked;
  }

  void _send(BuildContext context) {
    final date = _date.value;
    final reasonCode = _reasonCode.value;
    if (date == null || reasonCode == null) {
      return;
    }
    context
        .read<LotteonOrderActionBloc>()
        .add(LotteonDeliveryAppointmentRequested(
          orderItemId: widget.order.id,
          body: {
            'appointmentDate': DateFormat('yyyy-MM-dd').format(date),
            'reasonCode': reasonCode,
            'detailCode': reasonCode == _lotteonMakingDelayCode
                ? _detailCode.value
                : null,
          },
        ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LotteonOrderActionBloc, LotteonOrderActionState>(
        listenWhen: (p, c) => c.appointmentSent && !p.appointmentSent,
        listener: (context, state) =>
            showSuccessToast(context, '발송 약정일 안내를 보냈습니다.'),
        builder: (context, state) {
          if (state.forbidden) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppCard(
              child: ListenableBuilder(
                listenable:
                    Listenable.merge([_open, _date, _reasonCode, _detailCode]),
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: state.sending
                          ? null
                          : () => _open.value = !_open.value,
                      child: const Text('발송 약정일 안내'),
                    ),
                    if (_open.value) ..._buildForm(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      );

  List<Widget> _buildForm(BuildContext context, LotteonOrderActionState state) {
    final date = _date.value;
    final reasonCode = _reasonCode.value;
    final needsDetail = reasonCode == _lotteonMakingDelayCode;
    final ready = !state.sending &&
        date != null &&
        reasonCode != null &&
        (!needsDetail || _detailCode.value != null);
    final dateText = date == null ? '-' : DateFormat('yyyy-MM-dd').format(date);
    return [
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: state.sending ? null : () => _pickDate(context),
        child: Text('발송 약정일 $dateText'),
      ),
      const SizedBox(height: 12),
      _reasonDropdown(
        label: '지연 사유',
        reasons: state.choices.appointmentReasons,
        value: reasonCode,
        onChanged: state.sending ? null : (value) => _reasonCode.value = value,
      ),
      if (needsDetail) ...[
        const SizedBox(height: 12),
        _reasonDropdown(
          label: '상세 사유',
          reasons: state.choices.appointmentDetailReasons,
          value: _detailCode.value,
          onChanged:
              state.sending ? null : (value) => _detailCode.value = value,
        ),
      ],
      if (state.choicesFailed)
        Text('사유 목록을 불러오지 못했습니다.', style: _hintStyle(context)),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: ready ? () => _send(context) : null,
        child: state.sending ? const AppBusyLabel('보내기') : const Text('보내기'),
      ),
    ];
  }
}
