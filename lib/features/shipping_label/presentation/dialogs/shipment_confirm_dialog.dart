import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
// Status label SSOT — the order history filter chips use the same helper.
import 'package:flutter_oklyn_mobile/features/order/domain/entities/order_item.dart';
import '../../data/models/shipment_confirm_result.dart';
import '../../domain/usecases/shipping_label_usecase.dart';
import '../bloc/shipment_confirm_bloc.dart';
import '../bloc/shipment_confirm_event.dart';
import '../bloc/shipment_confirm_state.dart';

/// 발송처리(운송장 업로드) 다이얼로그.
///
/// **용도**: 택배사가 운송장번호를 채운 결과 xlsx 를 업로드 → 서버가 주문번호로
///   매칭해 쿠팡 송장업로드(INSTRUCT→배송지시)를 배치 전송. 결과(성공/미매칭/실패)를 표시.
/// **사용법**: `showShipmentConfirmDialog(context)` 헬퍼로 연다(BlocProvider 스코프 자동 제공).
/// **반환값**: 업로드가 한 번이라도 성공하면 `true`, 아니면 `false`.
///   바깥 탭·안드로이드 뒤로가기로 닫으면 `null` — 호출부는 목록을 재조회하지 않는다.
/// **파일**: lib/features/shipping_label/presentation/dialogs/shipment_confirm_dialog.dart
///
/// ⚠️ 주문내역 페이지에서만 사용. role 클라이언트 게이트 없음(백엔드 403 의존).
/// ⚠️ 다이얼로그를 닫으면 BLoC 폐기 → 다음에 열면 초기 상태.
Future<bool?> showShipmentConfirmDialog(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) =>
            ShipmentConfirmBloc(useCase: getIt<ShippingLabelUseCase>()),
        child: const ShipmentConfirmDialog(),
      ),
    );

class ShipmentConfirmDialog extends StatelessWidget {
  const ShipmentConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: BlocBuilder<ShipmentConfirmBloc, ShipmentConfirmState>(
          builder: (context, state) {
            final bloc = context.read<ShipmentConfirmBloc>();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '발송처리 (운송장 업로드)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            Navigator.pop(context, state.hasSucceeded),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: state.result == null
                          ? _UploadPanel(state: state, bloc: bloc)
                          : _ResultPanel(result: state.result!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Actions(state: state, bloc: bloc),
                ],
              ),
            );
          },
        ),
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
        const Text(
          '택배사가 운송장번호를 채운 결과 xlsx 를 업로드하세요. '
          '서버가 주문번호로 매칭해 쿠팡에 송장을 등록합니다.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          '이미 발송처리된 주문은 자동으로 제외됩니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: state.isUploading ? null : () => bloc.add(const PickFile()),
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
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

/// 결과 있음: 요약 + 미매칭 + 전송 제외 + 실패 상세.
class _ResultPanel extends StatelessWidget {
  final ShipmentConfirmResult result;

  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    // Group skipped orders by status so a 60-row file folds into 1~2 lines.
    final skippedGroups = <String, List<String>>{};
    for (final s in result.skipped) {
      skippedGroups.putIfAbsent(s.status, () => []).add(s.orderId);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 요약 행
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text('총 ${result.totalRows}행'),
            Text('매칭 ${result.matchedOrders}주문'),
            Text(
              '성공 ${result.succeeded}건',
              style: TextStyle(
                  color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
            Text(
              '실패 ${result.failed.length}건',
              style: TextStyle(
                color: result.failed.isEmpty
                    ? Colors.grey
                    : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('미매칭 ${result.unmatched.length}건'),
            Text('제외 ${result.skipped.length}건'),
          ],
        ),
        if (result.failed.isEmpty &&
            result.unmatched.isEmpty &&
            result.skipped.isEmpty &&
            result.succeeded > 0) ...[
          const SizedBox(height: 12),
          Text(
            '모든 박스가 정상 처리되었습니다.',
            style: TextStyle(color: Colors.green.shade700),
          ),
        ],
        if (result.unmatched.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('미매칭 주문번호',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            'order_item 없거나 쿠팡이 아니라 스킵됨',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: result.unmatched
                .map((o) => Chip(
                      label: Text(o, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
        if (skippedGroups.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('전송 제외 (이미 발송처리됨)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            '배송지시 이상으로 넘어간 주문 — 실패가 아닙니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          ...skippedGroups.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${e.key.isEmpty ? '알 수 없음' : getOrderStatusLabel(e.key)}'
                      ' · ${e.value.length}건',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: e.value
                        .map((o) => Chip(
                              label:
                                  Text(o, style: const TextStyle(fontSize: 12)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (result.failed.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('실패 상세', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...result.failed.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  '${f.shipmentBoxId} · ${f.resultCode} · ${f.message}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
            ),
          ),
        ],
      ],
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
    if (state.result != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
    final canUpload = state.fileBytes != null && !state.isUploading;
    return ElevatedButton(
      onPressed: canUpload ? () => bloc.add(const UploadShipment()) : null,
      child: state.isUploading
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('처리 중...'),
              ],
            )
          : const Text('업로드'),
    );
  }
}
