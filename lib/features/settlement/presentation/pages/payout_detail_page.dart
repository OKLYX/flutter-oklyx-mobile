import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/settlement/domain/entities/settlement.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_detail_bloc.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_detail_event.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/bloc/payout_detail_state.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/utils/settlement_format.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/month_check_card.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/payout_order_list.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/recon_block_a_card.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/recon_block_b_card.dart';
import 'package:flutter_oklyn_mobile/features/settlement/presentation/widgets/settlement_message_box.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// Payout detail page (FEATURE_2610_20 / D22 · D23 · D29 · D34 · D38 · D39 ·
/// D40) — the mobile twin of the web `PayoutDetailContainer`.
///
/// 🔴 No refresh call lives here — every number is the server's stored value.
/// ⚠️ 「지급 완료」 / 「지급 완료 취소」 show only for 11st payouts; they write the local
/// payout only.
/// ⚠️ The export file name = 「정산_{channel}_{period}」 (D23, the same as the
/// web).
class PayoutDetailPage extends StatelessWidget {
  final int payoutId;

  const PayoutDetailPage({required this.payoutId, super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<PayoutDetailBloc>(param1: payoutId)
          ..add(const PayoutDetailStarted()),
        child: const _PayoutDetailView(),
      );
}

class _PayoutDetailView extends StatelessWidget {
  const _PayoutDetailView();

  static String _channel(PayoutSummary payout) =>
      channelLabel(payout.platform, payout.accountAlias, payout.accountId);

  /// Characters a file name cannot carry — the channel alias is free text.
  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();

  Future<void> _copy(BuildContext context, ReconLineView line) async {
    final text = [
      '주문번호 ${line.externalOrderId ?? '-'}',
      '옵션ID ${line.platformOptionId ?? '-'}',
      '인식일 ${line.recognitionDate ?? '-'}',
      '지급일 ${line.settlementDate ?? '-'}',
      '정산유형 ${settlementTypeLabel(line.settlementType)}',
    ].join(' / ');
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } on Exception catch (_) {
      if (context.mounted) {
        showErrorToast(context, '복사에 실패했습니다.');
      }
      return;
    }
    if (context.mounted) {
      showSuccessToast(context, '식별자를 복사했습니다.');
    }
  }

  Future<void> _save(BuildContext context, PayoutDetailState state) async {
    final report = state.report;
    final bytes = state.exportBytes;
    if (report == null || bytes == null) {
      return;
    }
    final payout = report.payout;
    final period = formatDateRange(payout.recognitionFrom, payout.recognitionTo)
        .replaceAll(RegExp(r'\s'), '');
    try {
      final path = await FileSaver.instance.saveAs(
        name: '정산_${_safe(_channel(payout))}_${_safe(period)}',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (path == null || path.isEmpty) {
        return;
      }
    } on Exception catch (_) {
      if (context.mounted) {
        showErrorToast(context, '파일 저장에 실패했습니다.');
      }
      return;
    }
    if (context.mounted) {
      showSuccessToast(context, '정산 내역을 저장했습니다.');
    }
  }

  /// D38: the picker starts at the remittance date, or today (KST) when that
  /// is still ahead, and its last day is today (KST).
  Future<void> _pickPaidOn(BuildContext context, PayoutSummary payout) async {
    final bloc = context.read<PayoutDetailBloc>();
    final today = todayKst();
    final remittance = DateTime.tryParse(payout.settlementDate ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate:
          remittance == null || remittance.isAfter(today) ? today : remittance,
      firstDate: DateTime(today.year - 3),
      lastDate: today,
      helpText: '실제 입금일',
    );
    if (picked != null) {
      bloc.add(PayoutMarkPaidRequested(toDateText(picked)));
    }
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '정산 상세',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocConsumer<PayoutDetailBloc, PayoutDetailState>(
          listenWhen: (previous, current) =>
              previous.toastTick != current.toastTick ||
              previous.exportTick != current.exportTick,
          listener: (context, state) {
            // A toast and an export never land in the same emit — each changes
            // its own tick.
            if (state.toastMessage.isNotEmpty) {
              if (state.toastIsError) {
                showErrorToast(context, state.toastMessage);
              } else {
                showSuccessToast(context, state.toastMessage);
              }
            }
            if (state.exportBytes != null) {
              _save(context, state);
            }
          },
          builder: (context, state) {
            final bloc = context.read<PayoutDetailBloc>();
            final report = state.report;
            if (state.forbidden) {
              return const AppPageBody(children: [AppEmpty('관리자만 볼 수 있습니다.')]);
            }
            if (state.loading && report == null) {
              return const AppPageBody(children: [AppLoading()]);
            }
            if (report == null) {
              return AppPageBody(
                children: [
                  AppErrorBox(
                    message: state.error.isNotEmpty
                        ? state.error
                        : '지급 묶음을 찾을 수 없습니다.',
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () =>
                              bloc.add(const PayoutDetailRetried()),
                          child: const Text('다시 시도'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.goNamed(Routes.settlementPayouts),
                          child: const Text('목록으로'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final payout = report.payout;
            final showBlockB =
                report.blockB.labels.isNotEmpty || state.unmatchedOnly;
            return AppPageBody(
              children: [
                _header(context, state, payout),
                if (payout.reconStatus == 'AMOUNT_ONLY') ...[
                  const SizedBox(height: 12),
                  SettlementMessageBox(
                    tone: SettlementMessageTone.neutral,
                    message: 'ⓘ 금액만 기록된 지급입니다 — '
                        '${withSubjectParticle(marketName(payout.platform))} '
                        '어느 주문이 포함됐는지 알려주지 않아 판매 내역을 대조할 수 없습니다.',
                  ),
                ],
                if (payout.reconStatus == 'NO_TOTAL') ...[
                  const SizedBox(height: 12),
                  const SettlementMessageBox(
                      tone: SettlementMessageTone.neutral,
                      message: 'ⓘ $kNoTotalNotice'),
                ],
                if (report.monthCheck != null) ...[
                  const SizedBox(height: 12),
                  MonthCheckCard(
                    monthCheck: report.monthCheck!,
                    typeLabel: settlementTypeLabel(payout.settlementType),
                    platform: payout.platform,
                  ),
                ],
                const SizedBox(height: 12),
                ReconBlockACard(
                  blockA: report.blockA,
                  platform: payout.platform,
                  onShowUnmatched: () => bloc.add(const PayoutUnmatchedShown()),
                ),
                if (showBlockB) ...[
                  const SizedBox(height: 12),
                  ReconBlockBCard(
                    blockB: report.blockB,
                    expandedLabel: state.expandedLabel,
                    unmatchedOnly: state.unmatchedOnly,
                    lines: state.lines,
                    linesLoading: state.linesLoading,
                    linesError: state.linesError,
                    onExpand: (label) => bloc.add(PayoutLabelToggled(label)),
                    onToggleUnmatched: () =>
                        bloc.add(const PayoutUnmatchedToggled()),
                    onCopy: (line) => _copy(context, line),
                  ),
                ],
                const SizedBox(height: 12),
                PayoutOrderList(
                  lines: state.orderLines,
                  loading: state.orderLinesLoading,
                  error: state.orderLinesError,
                  onCopy: (line) => _copy(context, line),
                ),
              ],
            );
          },
        ),
      );

  Widget _header(
      BuildContext context, PayoutDetailState state, PayoutSummary payout) {
    final bloc = context.read<PayoutDetailBloc>();
    final muted = TextStyle(
        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    final markable = payout.platform == 'ELEVENST';
    final paidOn = payout.finalSettlementDate ?? payout.settlementDate ?? '—';
    final period =
        formatDateRange(payout.recognitionFrom, payout.recognitionTo);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_channel(payout)} · '
            '${settlementTypeLabel(payout.settlementType)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('판매기간 $period', style: muted),
          Text.rich(
            TextSpan(
              style: muted,
              children: [
                TextSpan(text: '지급일 $paidOn ('),
                TextSpan(
                  text: payoutStatusText(payout),
                  style: payout.paymentCheckNeeded
                      ? const TextStyle(color: AppColors.warningForeground)
                      : null,
                ),
                TextSpan(text: ') · 지급액 ${formatMoney(payout.finalAmount)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (markable && payout.status == 'PAID')
                OutlinedButton(
                  onPressed: state.marking
                      ? null
                      : () => bloc.add(const PayoutUnmarkPaidRequested()),
                  child: state.marking
                      ? const AppBusyLabel('지급 완료 취소')
                      : const Text('지급 완료 취소'),
                ),
              if (markable && payout.status != 'PAID')
                FilledButton(
                  onPressed:
                      state.marking ? null : () => _pickPaidOn(context, payout),
                  child: state.marking
                      ? const AppBusyLabel('지급 완료')
                      : const Text('지급 완료'),
                ),
              OutlinedButton(
                onPressed: state.exporting
                    ? null
                    : () => bloc.add(const PayoutExportRequested()),
                child: state.exporting
                    ? const AppBusyLabel('엑셀 다운로드')
                    : const Text('엑셀 다운로드'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
