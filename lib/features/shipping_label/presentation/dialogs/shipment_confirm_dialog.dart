import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/order/domain/usecases/order_usecase.dart';
// Status label SSOT — the order history filter chips use the same helper.
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_item.dart';
import '../../data/models/reservation_create_result.dart';
import '../../data/models/shipment_confirm_result.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import '../bloc/shipment_confirm_bloc.dart';
import '../bloc/shipment_confirm_event.dart';
import '../bloc/shipment_confirm_state.dart';
import '../utils/reserved_time_picker.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// 발송처리(운송장 업로드) 다이얼로그.
///
/// **용도**: 택배사가 운송장번호를 채운 결과 xlsx 를 올리고 [지금 발송]·[예약 발송] 버튼으로 보낸다.
///   [지금 발송] = 기존 요청 그대로 — 서버가 주문번호로 매칭해 쿠팡 송장업로드(상품준비중→발송처리)를
///   배치 전송하고 결과(성공/미매칭/실패)를 표시한다. 「내부 상품준비중」·「발송대기중」 주문은 서버가
///   발주처리 → 송장 등록 순으로 보낸다(FEATURE_2609_75 / D27) — 화면 흐름은 같다.
///   [예약 발송] = 「내부 상품준비중」 배송건의 송장만 저장하고 예약 시각에 서버가 발주처리·송장 등록을 한다(D20).
///   저장된 송장 모드(`storedOrderItemIds` 전달, D18) = 파일 선택이 없고 두 버튼이 저장된 송장으로 보낸다. 결과 화면은 같다.
/// **사용법**: `showShipmentConfirmDialog(context)` 헬퍼로 연다(BlocProvider 스코프 자동 제공).
///   저장된 송장 모드 = `showShipmentConfirmDialog(context, storedOrderItemIds: ids)`(출고관리 [저장된 송장으로 발송]).
///   열 때 기본 예약 시각(주문관리 설정, D12)을 1회 읽는다.
/// **반환값**: 업로드·예약이 한 번이라도 성공하면 `true`, 아니면 `false`.
///   바깥 탭·안드로이드 뒤로가기로 닫으면 `null` — 호출부는 목록을 재조회하지 않는다.
/// 결과는 요약 칩 6개 + 선택한 칩의 상세 표 1개(PLAN 2609_12 D2 — 목록이 있는 3개만 클릭 가능).
/// **파일**: lib/features/shipping_label/presentation/dialogs/shipment_confirm_dialog.dart
///
/// ⚠️ 주문내역 페이지에서만 사용. role 클라이언트 게이트 없음(백엔드 403 의존).
/// ⚠️ 다이얼로그를 닫으면 BLoC 폐기 → 다음에 열면 초기 상태.
Future<bool?> showShipmentConfirmDialog(
  BuildContext context, {
  List<int>? storedOrderItemIds,
}) =>
    showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => ShipmentConfirmBloc(
          useCase: getIt<ShippingLabelUseCase>(),
          orderUseCase: getIt<OrderUseCase>(),
          storedOrderItemIds: storedOrderItemIds,
        )..add(const LoadDefaultExecuteAt()),
        child: const ShipmentConfirmDialog(),
      ),
    );

class ShipmentConfirmDialog extends StatelessWidget {
  const ShipmentConfirmDialog({super.key});

  Widget _header(BuildContext context, ShipmentConfirmState state) => Row(
        children: [
          Expanded(
            child: Text(
              context.read<ShipmentConfirmBloc>().storedOrderItemIds != null
                  ? '발송처리 (저장된 송장)'
                  : '발송처리 (운송장 업로드)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, state.hasSucceeded),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // BlocBuilder sits above the size box on purpose: the result/upload height
      // split needs `state.result`, which is not readable outside the builder.
      child: BlocBuilder<ShipmentConfirmBloc, ShipmentConfirmState>(
        builder: (context, state) {
          final bloc = context.read<ShipmentConfirmBloc>();
          // Keep 560 from overflowing a small phone.
          final maxH =
              math.min<double>(560, MediaQuery.sizeOf(context).height * 0.8);

          if (state.reserveResult != null) {
            // 예약 결과 화면 — 지금 발송 결과와 같은 고정 높이, 본문만 스크롤.
            return SizedBox(
              width: 480,
              height: maxH,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context, state),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _ReservePanel(result: state.reserveResult!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Actions(state: state, bloc: bloc),
                  ],
                ),
              ),
            );
          }

          if (state.result != null) {
            // Result view: fixed height so switching chips never resizes the
            // dialog (PLAN 2609_12 D6). Only the detail area scrolls.
            return SizedBox(
              width: 480,
              height: maxH,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context, state),
                    const Divider(),
                    Expanded(
                      child: _ResultPanel(
                        result: state.result!,
                        selectedBucket: state.selectedBucket,
                        bloc: bloc,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Actions(state: state, bloc: bloc),
                  ],
                ),
              ),
            );
          }

          // Upload view: content height — fixing it would leave one file button
          // floating in an empty dialog.
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480, maxHeight: maxH),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, state),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: _UploadPanel(state: state, bloc: bloc),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Actions(state: state, bloc: bloc),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 결과 없음: 안내 + 파일 선택 + 에러 배너.
class _UploadPanel extends StatelessWidget {
  final ShipmentConfirmState state;
  final ShipmentConfirmBloc bloc;

  const _UploadPanel({required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bloc.storedOrderItemIds != null)
          // 저장된 송장 모드(D18) — 파일 선택이 없다.
          const Text(
            '선택한 주문의 저장된 송장으로 보냅니다. 송장이 없는 주문은 제외됩니다.',
            style: TextStyle(fontSize: 13),
          )
        else ...[
          const Text(
            '택배사가 운송장번호를 채운 결과 xlsx 를 업로드하세요. '
            '서버가 주문번호로 매칭해 쿠팡에 송장을 등록합니다.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '이미 발송처리된 주문은 자동으로 제외됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: state.isUploading || state.isReserving
                ? null
                : () => bloc.add(const PickFile()),
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('파일 선택'),
          ),
          if (state.fileName != null) ...[
            const SizedBox(height: 8),
            Text(
              '선택: ${state.fileName}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
        // 예약 발송 시각(D20) — 기본값 = 주문관리 설정의 다음 도래 시각(D12). 한국시간.
        const SizedBox(height: 16),
        const Text(
          '예약 시각 (한국시간)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: state.isUploading || state.isReserving
              ? null
              : () async {
                  final picked =
                      await pickReservedExecuteAt(context, state.executeAt);
                  if (picked != null && !bloc.isClosed) {
                    bloc.add(ChangeExecuteAt(picked));
                  }
                },
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(state.executeAt == null
              ? '시각 선택'
              : formatOrderDateTime(state.executeAt)),
        ),
        const SizedBox(height: 4),
        Text(
          '[예약 발송]은 「내부 상품준비중」 주문의 송장만 저장하고, 이 시각에 쿠팡 발주처리와 송장 등록을 합니다. '
          '[지금 발송]은 바로 전송합니다(「내부 상품준비중」·「발송대기중」 주문은 발주처리 후 송장 등록).',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              border: Border.all(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              state.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 예약 결과 — 건수 요약 + 제외된 주문 표(사유는 서버 문구 그대로, D20).
class _ReservePanel extends StatelessWidget {
  final ReservationCreateResult result;

  const _ReservePanel({required this.result});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              border: Border.all(color: AppColors.successBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '예약 ${result.reservedShipments}건 · 송장 수정 ${result.updatedInvoices}건 · '
              '제외 ${result.excluded.length}건\n'
              '예약 시각 ${formatOrderDateTime(result.executeAt)}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.successForeground),
            ),
          ),
          if (result.excluded.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('예약 제외', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ResultTable(
              headers: const ['주문번호', '사유'],
              rows: [
                for (final row in result.excluded) [row.orderId, row.reason],
              ],
              flex: const [5, 6],
            ),
          ],
        ],
      );
}

/// 결과 요약 칩 하나의 명세.
/// [bucket] 이 null 이면 서버가 숫자만 주는 칩 = 열 목록이 없다(PLAN 2609_12 D2).
class _ChipSpec {
  final ResultBucket? bucket;
  final String label;
  final int count;
  final Color? color;

  const _ChipSpec(this.label, this.count, {this.bucket, this.color});
}

/// 결과 있음: 요약 칩 줄(고정) + 선택한 칩의 상세 표(스크롤).
class _ResultPanel extends StatelessWidget {
  final ShipmentConfirmResult result;
  final ResultBucket? selectedBucket;
  final ShipmentConfirmBloc bloc;

  const _ResultPanel({
    required this.result,
    required this.selectedBucket,
    required this.bloc,
  });

  List<_ChipSpec> _chips(BuildContext context) => [
        _ChipSpec('요청 건수', result.totalRows),
        _ChipSpec('매칭', result.matchedOrders),
        _ChipSpec(
          '성공',
          result.succeeded,
          color: AppColors.successForeground,
        ),
        _ChipSpec(
          '실패',
          result.failed.length,
          bucket: ResultBucket.failed,
          color: result.failed.isEmpty
              ? null
              : Theme.of(context).colorScheme.onErrorContainer,
        ),
        _ChipSpec('미매칭', result.unmatched.length,
            bucket: ResultBucket.unmatched),
        _ChipSpec('전송 제외', result.skipped.length, bucket: ResultBucket.skipped),
      ];

  Widget _chip(_ChipSpec spec) {
    final text = '${spec.label} : ${spec.count}';
    final clickable = spec.bucket != null && spec.count > 0;
    if (!clickable) {
      // Static chip: counts-only bucket, or an empty one. A disabled ChoiceChip
      // would read as "tappable but broken" (PLAN 2609_12 D3).
      return Chip(
        label: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: spec.color,
            fontWeight: spec.color == null ? null : FontWeight.bold,
          ),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    final selected = selectedBucket == spec.bucket;
    return ChoiceChip(
      selected: selected,
      // Match the web's primary selection (blue-600 remaps to brand main).
      selectedColor: AppColors.brandMain,
      // A checkmark would make each chip a different width.
      showCheckmark: false,
      onSelected: (_) => bloc.add(SelectResultBucket(spec.bucket!)),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          // Selection wins over the tone color.
          color: selected ? AppColors.foregroundLight : spec.color,
          fontWeight: !selected && spec.color != null ? FontWeight.bold : null,
        ),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final spec in _chips(context)) _chip(spec)],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(child: _detail(context)),
          ),
        ],
      );

  Widget _detail(BuildContext context) {
    switch (selectedBucket) {
      case ResultBucket.failed:
        return _failedDetail(context);
      case ResultBucket.unmatched:
        return _unmatchedDetail(context);
      case ResultBucket.skipped:
        return _skippedDetail(context);
      case null:
        return _emptySelection(context);
    }
  }

  Widget _emptySelection(BuildContext context) {
    final allClean = result.failed.isEmpty &&
        result.unmatched.isEmpty &&
        result.skipped.isEmpty;
    if (allClean && result.succeeded > 0) {
      return const Text(
        '모든 박스가 정상 처리되었습니다.',
        style: TextStyle(color: AppColors.successForeground),
      );
    }
    return Text(
      '칩을 눌러 해당 주문 목록을 확인하세요.',
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _title(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );

  Widget _caption(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _failedDetail(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('실패 상세'),
          const SizedBox(height: 8),
          _ResultTable(
            headers: const ['박스 ID', '코드', '메시지'],
            rows: [
              for (final f in result.failed)
                [f.shipmentBoxId, f.resultCode, f.message],
            ],
            flex: const [3, 4, 6],
            scrollHorizontally: true,
          ),
        ],
      );

  Widget _unmatchedDetail(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title('미매칭 주문번호'),
          _caption(
              context,
              bloc.storedOrderItemIds != null
                  ? '저장된 송장이 없거나 내부 단계 주문이 아니라 제외됨'
                  : 'order_item 없거나 쿠팡이 아니라 스킵됨'),
          const SizedBox(height: 8),
          _ResultTable(
            headers: const ['#', '주문번호'],
            rows: [
              for (var i = 0; i < result.unmatched.length; i++)
                ['${i + 1}', result.unmatched[i]],
            ],
            flex: const [1, 6],
          ),
        ],
      );

  Widget _skippedDetail(BuildContext context) {
    String label(OrderStatus s) => getOrderStatusLabel(s);

    // Sort and summary both key on the neutral status — if they diverge the
    // reader sees "발송처리 12" above a table that starts with 배송중.
    final rows = [...result.skipped]..sort((a, b) {
        final byStatus = a.status.index.compareTo(b.status.index);
        return byStatus != 0 ? byStatus : a.orderId.compareTo(b.orderId);
      });

    // Walking the sorted rows counts runs without a group map.
    final codes = <OrderStatus>[];
    final counts = <int>[];
    for (final r in rows) {
      if (codes.isNotEmpty && codes.last == r.status) {
        counts[counts.length - 1]++;
      } else {
        codes.add(r.status);
        counts.add(1);
      }
    }
    final summary = [
      for (var i = 0; i < codes.length; i++) '${label(codes[i])} ${counts[i]}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('전송 제외'),
        _caption(context, '이미 발송처리된 상태입니다.'),
        const SizedBox(height: 8),
        Text(
          summary,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _ResultTable(
          headers: const ['주문번호', '상태'],
          rows: [
            for (final r in rows) [r.orderId, label(r.status)],
          ],
          flex: const [5, 3],
        ),
      ],
    );
  }
}

/// 결과 상세 표 — 헤더 1행 + 데이터 행.
///
/// [flex] = 열 너비 비율(합이 얼마든 상관없다). [scrollHorizontally] 는 실패 표처럼
/// 쿠팡 원문 메시지가 들어가 폭이 모자란 표에만 켠다 — 2열 표에 켜면 셀이 내용 폭으로
/// 쪼그라들어 오히려 읽기 나빠진다.
class _ResultTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int> flex;
  final bool scrollHorizontally;

  const _ResultTable({
    required this.headers,
    required this.rows,
    required this.flex,
    this.scrollHorizontally = false,
  });

  static const _cellPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);

  Widget _row(List<String> cells, TextStyle style) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Padding(
                  padding: _cellPadding, child: Text(cells[i], style: style)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: _row(
              headers,
              TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ),
        for (final r in rows) ...[
          const Divider(height: 1),
          _row(r, const TextStyle(fontSize: 12)),
        ],
      ],
    );
    final bordered = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: table,
    );
    if (!scrollHorizontally) {
      return bordered;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: 560, child: bordered),
    );
  }
}

/// 하단 액션 버튼 — 결과 유무에 따라 분기.
class _Actions extends StatelessWidget {
  final ShipmentConfirmState state;
  final ShipmentConfirmBloc bloc;

  const _Actions({required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) {
    if (state.result != null || state.reserveResult != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 저장된 송장 모드는 파일이 없다 — [다른 파일 업로드]를 그리지 않는다(D18).
          if (bloc.storedOrderItemIds == null)
            TextButton(
              onPressed: () => bloc.add(const ResetShipmentConfirm()),
              child: const Text('다른 파일 업로드'),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, state.hasSucceeded),
            child: const Text('닫기'),
          ),
        ],
      );
    }
    final busy = state.isUploading || state.isReserving;
    // 저장된 송장 모드(D18)는 파일 없이 보낼 수 있다.
    final canUpload =
        (bloc.storedOrderItemIds != null || state.fileBytes != null) && !busy;
    final canReserve = canUpload && state.executeAt != null;
    Widget progress(String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        );
    // [예약 발송] stays green — written here, not in the theme · [지금 발송] = the upload button (D20 · D101).
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
            onPressed:
                canReserve ? () => bloc.add(const ReserveShipment()) : null,
            child: state.isReserving
                ? progress('예약 중...')
                : const Text('예약 발송'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed:
                canUpload ? () => bloc.add(const UploadShipment()) : null,
            child: state.isUploading
                ? progress('처리 중...')
                : const Text('지금 발송'),
          ),
        ),
      ],
    );
  }
}
