import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/platform_display.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/features/purchase_list/presentation/widgets/product_thumbnail.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_confirm_dialog.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/packing.dart';
import '../../domain/entities/packing_history.dart';
import '../bloc/packing_bloc.dart';
import '../bloc/packing_event.dart';
import '../bloc/packing_state.dart';
import '../widgets/box_change_sheet.dart';

/// App 「포장 작업」 screen (`/stock/packing`, FEATURE_2611_03 / PLAN D10 ·
/// D22 · D23 · D26 · FEATURE_2611_06 / PLAN D21 · D22 · D24).
///
/// - One input field (no camera, no new package, no permission — D22): an
///   invoice number while no box is open, a product barcode while packing.
/// - Tabs 「오늘 완료」 · 「작업 대상」 always show below the open box (or
///   below the input field while waiting). 「오늘 완료」 is picked on entry
///   and after a completion, a cancel or an unused close (FEATURE_2611_06 /
///   D24).
/// - 「오늘 완료」: today's packed boxes; a tap opens the box change sheet for
///   that parcel (`showBoxChangeSheet`, D21).
/// - 「작업 대상」: the work list; a tap opens that invoice only while no box
///   is open (R15).
/// - Packing: invoice card, lines with −/+, box recommendation with
///   [박스 변경] (the sheet only picks the box being packed — no server
///   change, D22) and the 「고른 상자」 line, buttons
///   [송장 미사용 처리] · [취소] · [이 박스 완료].
/// - Closed box: an unused box shows [미사용 되돌리기] (restore card, D26);
///   both kinds show [다음 송장 스캔].
/// **File**: lib/features/packing/presentation/pages/packing_page.dart
///
/// ⚠️ Every judgement is the server's (D27) — this page only draws the state.
class PackingPage extends StatelessWidget {
  const PackingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<PackingBloc>()..add(PackingStarted()),
        child: const _PackingView(),
      );
}

class _PackingView extends StatefulWidget {
  const _PackingView();

  @override
  State<_PackingView> createState() => _PackingViewState();
}

class _PackingViewState extends State<_PackingView> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    context.read<PackingBloc>().add(PackingInputSubmitted(value));
    _input.clear();
    // The default done action drops the focus — keep scanning.
    _focus.requestFocus();
  }

  Future<void> _confirmUnused() async {
    final bloc = context.read<PackingBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '송장 미사용 처리',
      message: '이 송장을 쓰지 않은 것으로 닫습니다. 출고·상자 기억을 남기지 않습니다. '
          '잘못 눌렀다면 이 송장을 다시 스캔한 뒤 [미사용 되돌리기] 로 되돌릴 수 있습니다. '
          '⚠️ 택배사의 송장이 취소되는 것은 아닙니다 — 실물 라벨은 폐기하세요.',
      confirmText: '미사용으로 닫기',
      isDangerous: true,
    );
    if (ok) {
      bloc.add(PackingUnusedRequested());
    }
  }

  Future<void> _confirmRestore() async {
    final bloc = context.read<PackingBloc>();
    final ok = await showAppConfirmDialog(
      context,
      title: '미사용 처리 되돌리기',
      message: '이 송장을 다시 포장할 수 있게 되돌립니다. '
          '되돌리면 바로 담기 화면이 열립니다.',
      confirmText: '되돌리기',
      cancelText: '미사용 처리 취소',
    );
    if (ok) {
      bloc.add(PackingRestoreRequested());
    }
  }

  void _showNotice(BuildContext context, PackingNotice notice) {
    switch (notice.kind) {
      case PackingNoticeKind.success:
        showSuccessToast(context, notice.message);
      case PackingNoticeKind.error:
        showErrorToast(context, notice.message);
      case PackingNoticeKind.info:
        showNoticeToast(context, notice.message);
    }
  }

  @override
  Widget build(BuildContext context) => ScaffoldWithNavBar(
        title: '포장 작업',
        navBarIndex: 2,
        showAppBarDrawerButton: false,
        body: BlocConsumer<PackingBloc, PackingState>(
          listenWhen: (previous, current) => previous.notice != current.notice,
          listener: (context, state) {
            final notice = state.notice;
            if (notice != null) {
              _showNotice(context, notice);
            }
          },
          builder: (context, state) {
            final scan = state.scan;
            return AppPageBody(
              children: [
                _inputField(state),
                const SizedBox(height: 16),
                if (scan != null) ...[
                  if (scan.parcel.status == ParcelStatus.pending)
                    ..._packing(context, state, scan)
                  else
                    _closed(context, state, scan),
                  const SizedBox(height: 16),
                ],
                _tabs(context, state),
                const SizedBox(height: 8),
                if (state.tab == PackingTab.done)
                  ..._done(context, state)
                else
                  ..._waiting(context, state),
              ],
            );
          },
        ),
      );

  Widget _inputField(PackingState state) {
    final scan = state.scan;
    final closed = scan != null && scan.parcel.status != ParcelStatus.pending;
    return TextField(
      controller: _input,
      focusNode: _focus,
      autofocus: true,
      // Not `enabled: false` — that drops the focus for good; `readOnly`
      // keeps it and reopens the input when it turns off.
      readOnly: state.busy || closed,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: scan == null ? '송장번호를 스캔하거나 입력하세요' : '물품 바코드를 스캔하거나 입력하세요',
      ),
      onSubmitted: _submit,
    );
  }

  Widget _tabs(BuildContext context, PackingState state) {
    final bloc = context.read<PackingBloc>();
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PackingTab>(
        segments: const [
          ButtonSegment(value: PackingTab.done, label: Text('오늘 완료')),
          ButtonSegment(value: PackingTab.pending, label: Text('작업 대상')),
        ],
        selected: {state.tab},
        showSelectedIcon: false,
        onSelectionChanged: (set) => bloc.add(PackingTabSelected(set.first)),
      ),
    );
  }

  /// 「오늘 완료」 list (FEATURE_2611_06 / D21).
  List<Widget> _done(BuildContext context, PackingState state) {
    if (state.doneLoading && state.done.isEmpty) {
      return const [AppLoading()];
    }
    if (state.done.isEmpty) {
      return const [AppEmpty('오늘 완료한 박스가 없습니다')];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _doneCells(
          const Text('No', textAlign: TextAlign.right),
          const Text('시각'),
          const Text('송장'),
          const Text('상자'),
        ),
      ),
      const SizedBox(height: 4),
      for (var i = 0; i < state.done.length; i++) ...[
        if (i > 0) const AppRowGap(),
        _doneRow(state, state.done[i], state.done.length - i),
      ],
    ];
  }

  Widget _doneRow(PackingState state, PackingHistoryEntry entry, int no) {
    final changedAt = entry.changedAt;
    final time = changedAt.length >= 16 ? changedAt.substring(11, 16) : '-';
    return AppCard.row(
      onTap: state.busy ? null : () => _changeDoneBox(entry),
      child: _doneCells(
        Text('$no', textAlign: TextAlign.right),
        Text(time),
        Text(entry.invoiceNumber),
        Text(entry.boxName ?? '-'),
      ),
    );
  }

  /// The same column widths for the head row and every row.
  Widget _doneCells(Widget no, Widget time, Widget invoice, Widget box) => Row(
        children: [
          SizedBox(width: 32, child: no),
          const SizedBox(width: 12),
          SizedBox(width: 48, child: time),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: invoice),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: box),
        ],
      );

  Future<void> _changeDoneBox(PackingHistoryEntry entry) async {
    final bloc = context.read<PackingBloc>();
    final box = await showBoxChangeSheet(
      context,
      parcelId: entry.parcelId,
      selectedPackageId: entry.boxPackageId,
    );
    if (box != null) {
      bloc.add(PackingDoneBoxChanged(box.type));
    }
  }

  /// [박스 변경] for the box being packed — picks only, no server change
  /// (FEATURE_2611_06 / D22).
  Future<void> _changePackingBox(int? selectedBoxId) async {
    final bloc = context.read<PackingBloc>();
    final box = await showBoxChangeSheet(
      context,
      parcelId: null,
      selectedPackageId: selectedBoxId,
    );
    if (box != null) {
      bloc
        ..add(PackingBoxSelected(box.id))
        ..add(PackingPackagesReloaded());
    }
  }

  /// 「작업 대상」 list — a row opens its invoice only while no box is open
  /// (R15).
  List<Widget> _waiting(BuildContext context, PackingState state) {
    final bloc = context.read<PackingBloc>();
    final locked = state.busy || state.scan != null;
    return [
      if (state.pendingLoading && state.pending.isEmpty)
        const AppLoading()
      else if (state.pending.isEmpty)
        const AppEmpty('작업할 박스가 없습니다')
      else
        for (var i = 0; i < state.pending.length; i++) ...[
          if (i > 0) const AppRowGap(),
          _pendingRow(context, state.pending[i], locked, bloc),
        ],
    ];
  }

  Widget _pendingRow(
    BuildContext context,
    PendingParcel parcel,
    bool locked,
    PackingBloc bloc,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard.row(
      onTap: locked
          ? null
          : () => bloc.add(PackingParcelOpened(parcel.invoiceNumber)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parcel.invoiceNumber, style: textTheme.titleSmall),
                Text(
                  '${parcel.carrierName ?? '택배사 미상'} · '
                  '${_boxLabel(parcel.totalParcels, parcel.parcelSeq)}',
                ),
                Text('${parcel.externalOrderId} · ${parcel.sellerName ?? '-'}'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('남은 ${parcel.remainingQty}개'),
        ],
      ),
    );
  }

  List<Widget> _packing(
    BuildContext context,
    PackingState state,
    PackingScan scan,
  ) {
    final bloc = context.read<PackingBloc>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final packedTotal = state.packedTotal;
    final requiredTotal = state.requiredTotal;
    final allPacked = requiredTotal > 0 && packedTotal >= requiredTotal;
    final notice = scan.isLastParcel
        ? '발송 상품 목록 내 물품을 모두 포장해야 합니다.'
        : scan.parcel.totalParcels > 1
            ? '분할 배송 상품입니다 — 이 박스에 담을 만큼만 담으세요'
            : null;
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scan.parcel.invoiceNumber, style: textTheme.headlineSmall),
            if (notice != null) ...[
              const SizedBox(height: 4),
              Text(notice),
            ],
            const SizedBox(height: 8),
            _field('판매자', scan.order.sellerName ?? '-'),
            _field('채널', _channel(scan.order)),
            _field(
              '수취인',
              scan.order.receiverName ?? scan.order.ordererName ?? '-',
            ),
            _field('주문번호', scan.order.externalOrderId),
            _field('택배사', scan.parcel.carrierName ?? '택배사 미상'),
            _field(
              '박스',
              _boxLabel(scan.parcel.totalParcels, scan.parcel.parcelSeq),
            ),
          ],
        ),
      ),
      if (scan.unexpanded.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(packingUnexpandedMessage, style: TextStyle(color: scheme.error)),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Text('발송 상품 목록', style: textTheme.titleMedium),
          ),
          Text('담음 $packedTotal / 필요 $requiredTotal'),
          if (allPacked) ...[
            const SizedBox(width: 8),
            const Text('담기 완료'),
          ],
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: requiredTotal > 0
            ? (packedTotal / requiredTotal).clamp(0.0, 1.0)
            : 0,
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < scan.remaining.length; i++) ...[
        if (i > 0) const AppRowGap(),
        _lineRow(context, state, scan.remaining[i], bloc),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: Text('박스 추천', style: textTheme.titleMedium)),
          OutlinedButton(
            onPressed: state.busy
                ? null
                : () => _changePackingBox(state.selectedBoxId),
            child: const Text('박스 변경'),
          ),
        ],
      ),
      if (_selectedBox(state) case final box?) ...[
        const SizedBox(height: 4),
        Text('고른 상자: ${box.type} · ${box.sizeLabel} · ${box.boxKind.label}'),
      ],
      const SizedBox(height: 8),
      ..._boxChoices(state, bloc),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: state.busy ? null : _confirmUnused,
            child: const Text('송장 미사용 처리'),
          ),
          OutlinedButton(
            onPressed: state.busy ? null : () => bloc.add(PackingCancelled()),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: packedTotal > 0 && !state.busy
                ? () => bloc.add(PackingCompleteRequested())
                : null,
            child: state.busy
                ? const AppBusyLabel('이 박스 완료')
                : const Text('이 박스 완료'),
          ),
        ],
      ),
    ];
  }

  Widget _lineRow(
    BuildContext context,
    PackingState state,
    PackingRemainingItem item,
    PackingBloc bloc,
  ) {
    final packed = state.packedOf(item);
    void change(int delta) => bloc.add(PackingLineChanged(
          orderLineId: item.orderLineId,
          productId: item.productId,
          delta: delta,
        ));
    return AppCard.row(
      child: Row(
        children: [
          ProductThumbnail(productId: item.productId, size: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName),
                Text(
                  item.itemName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: '하나 빼기',
            onPressed: state.busy || packed == 0 ? null : () => change(-1),
          ),
          Text('$packed / ${item.remainingQty}'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '하나 담기',
            onPressed: state.busy || packed >= item.remainingQty
                ? null
                : () => change(1),
          ),
        ],
      ),
    );
  }

  /// The picked box from every box, null when none is picked or it is not in
  /// the list (FEATURE_2611_06 / D22).
  Package? _selectedBox(PackingState state) {
    final id = state.selectedBoxId;
    if (id == null) {
      return null;
    }
    for (final package in state.packages) {
      if (package.id == id) {
        return package;
      }
    }
    return null;
  }

  List<Widget> _boxChoices(PackingState state, PackingBloc bloc) {
    if (state.candidatesLoading) {
      return const [AppLoading()];
    }
    void select(int id) => bloc.add(PackingBoxSelected(id));
    return [
      if (state.candidates.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final candidate in state.candidates)
              ChoiceChip(
                label: Text(
                  '${candidate.type} · ${_cm(candidate.widthCm)} × '
                  '${_cm(candidate.lengthCm)} × ${_cm(candidate.heightCm)} cm',
                ),
                selected: state.selectedBoxId == candidate.packageId,
                onSelected: (_) => select(candidate.packageId),
              ),
          ],
        )
      else ...[
        const Text('전체 상자에서 고르세요. 고른 상자는 이 조합으로 기억됩니다.'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final package in state.packages)
              ChoiceChip(
                label: Text('${package.type} · ${package.sizeLabel}'),
                selected: state.selectedBoxId == package.id,
                onSelected: (_) => select(package.id),
              ),
          ],
        ),
      ],
      if (state.selectedBoxId == null) ...[
        const SizedBox(height: 8),
        const Text('상자를 고르세요'),
      ],
    ];
  }

  Widget _closed(BuildContext context, PackingState state, PackingScan scan) {
    final unused = scan.parcel.status == ParcelStatus.unused;
    final bloc = context.read<PackingBloc>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unused ? '미사용 처리된 송장' : '출고 완료된 박스',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(scan.parcel.invoiceNumber),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (unused)
                FilledButton(
                  onPressed: state.busy ? null : _confirmRestore,
                  child: const Text('미사용 되돌리기'),
                ),
              OutlinedButton(
                onPressed:
                    state.busy ? null : () => bloc.add(PackingCancelled()),
                child: const Text('다음 송장 스캔'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 72, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );

  /// Alias when it is not blank, otherwise the market name, otherwise `-`.
  String _channel(PackingOrder order) {
    final alias = order.accountAlias?.trim() ?? '';
    if (alias.isNotEmpty) {
      return alias;
    }
    final platform = order.platform;
    return platform == null ? '-' : platformName(platform);
  }
}

/// 「{total}박스 중 {seq}번째」 for a split shipment, otherwise 「1박스」.
String _boxLabel(int totalParcels, int? parcelSeq) =>
    totalParcels > 1 ? '$totalParcels박스 중 ${parcelSeq ?? '-'}번째' : '1박스';

/// The `Package.sizeLabel` number rule — whole numbers without decimals,
/// otherwise one decimal.
String _cm(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
