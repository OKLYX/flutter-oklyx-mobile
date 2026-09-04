import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/core/utils/date_format.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/manual_shipment_result.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/shipping_label_preview_row.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_event.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/manual_shipment_state.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/order_sheet_bloc.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/order_sheet_event.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/presentation/bloc/order_sheet_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/order_item.dart';

// Platform display labels — same shape as product_listing_detail_page;
// unknown codes fall back to the raw value.
const Map<String, String> _platformLabels = {'COUPANG': '쿠팡'};

/// 주문 상세 페이지
///
/// **용도**: 주문내역 목록에서 선택한 단일 주문 항목의 전체 정보를 표시.
/// 프론트엔드 주문관리 > 주문내역의 `OrderDetailsModal`(읽기 전용)을 모바일로 이식.
///
/// **데이터 출처**:
/// 프론트와 동일하게 주문 상세 API는 존재하지 않으므로 별도 조회(BLoC) 없이
/// 목록에서 받은 [OrderItem]을 go_router `extra`로 전달받아 그대로 표시한다.
/// → 새로고침/딥링크 등으로 [order]가 null이면 목록으로 복귀.
///
/// **표시 필드(프론트 OrderDetailsModal과 동일)**:
/// 플랫폼 / 주문번호 / 박스 ID / 아이템 ID / 상품명 / 주문자 / 수취인 /
/// 주문수량 / 취소수량 / 보류수량 / 구매가능수량 / 상태 / 결제일 / 마켓 계정 ID
///
/// **UI**: 다른 상세 페이지(ProductListingDetailPage 등)와 동일한
/// `_InfoCard` / `_InfoRow` 카드 레이아웃을 따른다.
class OrderDetailPage extends StatelessWidget {
  final OrderItem? order;

  const OrderDetailPage({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문 상세',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.orderHistoryPath),
      body: order == null
          ? _buildMissing(context)
          : _buildContent(context, order!),
    );
  }

  // extra 로 전달된 주문 정보가 없는 경우(딥링크/새로고침) 목록 복귀를 유도한다.
  Widget _buildMissing(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('주문 정보를 찾을 수 없습니다.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go(Routes.orderHistoryPath),
            child: const Text('주문내역으로'),
          ),
        ],
      ),
    );
  }

  // 송장 접수시트/발송처리 섹션이 BLoC 을 필요로 하므로 BuildContext 를 받는다.
  // order == null 분기는 조회할 order.id 가 없어 BlocProvider 자체를 만들지 않는다.
  Widget _buildContent(BuildContext context, OrderItem o) {
    final isCoupang = o.platform == 'COUPANG';
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderSheetBloc>(create: (_) => getIt<OrderSheetBloc>()),
        // ⚠️ 쿠팡 주문일 때만 만든다 — 게이트를 렌더에만 걸면 비-쿠팡 주문을 열 때마다
        // ADMIN 전용 택배사 API 가 헛호출된다.
        if (isCoupang)
          BlocProvider<ManualShipmentBloc>(
            create: (_) =>
                getIt<ManualShipmentBloc>()..add(LoadCarrierOptions(o.platform)),
          ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ⚠️ BlocBuilder 는 이 카드 하나만 감싼다 — Column 이나 SingleChildScrollView 를
            // 감싸면 전송할 때마다 송장시트 섹션까지 리빌드돼 편집 중이던 택배수량이 튄다.
            _buildInfoCard(o, isCoupang: isCoupang),
            const SizedBox(height: 12),
            _InfoCard(
              title: '수량 정보',
              rows: [
                _InfoRow('주문수량', '${o.orderCount}'),
                _InfoRow('취소수량', '${o.cancelCount}'),
                _InfoRow('보류수량', '${o.holdCount}'),
                _InfoRow('구매가능수량', '${o.purchasableQty}'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: '기타',
              rows: [
                _InfoRow('결제일', formatOrderDateTime(o.paidAt)),
                _InfoRow('마켓 계정 ID', '${o.marketplaceAccountId}'),
              ],
            ),
            const SizedBox(height: 12),
            if (isCoupang) ...[
              _ManualShipmentSection(order: o),
              const SizedBox(height: 12),
            ],
            _OrderSheetSection(order: o),
            // ScaffoldWithNavBar 는 내비바를 오버레이하므로 하단 여백을 확보한다.
            SizedBox(
              height: kBottomNavigationBarHeight +
                  MediaQuery.paddingOf(context).bottom +
                  16,
            ),
          ],
        ),
      ),
    );
  }
}

//// 기본 정보 카드. 쿠팡 주문이면 `상태` 행만 단건 발송처리 결과를 따라간다 —
/// 신규 업로드가 성공하면 서버가 `resultStatus: 'DEPARTURE'` 를 주므로 재조회 없이 반영한다(D4).
Widget _buildInfoCard(OrderItem o, {required bool isCoupang}) {
  List<_InfoRow> rows(String status) => [
        _InfoRow('플랫폼', o.platform),
        _InfoRow('주문번호', o.externalOrderId),
        _InfoRow('박스 ID', o.externalBoxId ?? '-'),
        _InfoRow('아이템 ID', o.externalItemId),
        _InfoRow('상품명', o.itemName ?? '-'),
        _InfoRow('주문자', o.ordererName ?? '-'),
        _InfoRow('수취인', o.receiverName ?? '-'),
        // 목록과 같은 한글 라벨 SSOT 를 쓴다(라벨표 사본 금지).
        _InfoRow('상태', getOrderStatusLabel(status)),
      ];

  if (!isCoupang) {
    return _InfoCard(title: '기본 정보', rows: rows(o.status));
  }
  return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
    builder: (context, state) => _InfoCard(
      title: '기본 정보',
      rows: rows(state.result?.resultStatus ?? o.status),
    ),
  );
}

/// 정보 카드 (제목 + 라벨/값 행 목록). 다른 상세 페이지와 동일한 스타일.
class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 주문 상세 안 단건 발송처리 섹션 (인라인 확장 — 별도 화면/다이얼로그 없음).
///
/// **용도**: 택배사를 고르고 송장번호를 직접 입력해 이 주문의 박스 1개를 발송처리한다.
/// 결과 파일(xlsx)이 없는 건, 다른 택배사로 보낸 건, 잘못 올린 운송장 정정에 쓴다.
///
/// ⚠️ 전송 단위는 화면에 보이는 이 라인이 아니라 **이 라인이 속한 박스 전체**다(PLAN 2609_11 D1) —
/// 쿠팡은 박스의 모든 옵션에 같은 운송장번호를 보내야 받아준다.
/// ⚠️ 신규 업로드 / 송장수정 **모드는 서버가 주문 상태로 결정**한다(D3). 여기서는 버튼 라벨만 바꾼다.
/// ⚠️ 쿠팡이 응답을 준 뒤에는(성공·부분실패 모두) 입력을 잠근다(D14) — 재전송은
/// DUPLICATE_INVOICE_NUMBER 를 부른다. 요청 자체가 실패했을 때는 잠그지 않는다(아무것도 안 갔다).
/// ⚠️ 권한 게이트는 클라이언트에 두지 않는다. 다만 택배사 조회가 403 이면 섹션을 숨긴다 —
/// 안 그러면 비-ADMIN 사용자에게 영원히 실패하는 `다시 시도` 버튼만 남는다.
///
/// 송장번호는 BLoC 상태로 올리지 않는다(글자마다 emit 하면 리빌드가 낭비다) →
/// [TextEditingController] 를 들기 위해 StatefulWidget.
class _ManualShipmentSection extends StatefulWidget {
  final OrderItem order;

  const _ManualShipmentSection({required this.order});

  @override
  State<_ManualShipmentSection> createState() => _ManualShipmentSectionState();
}

class _ManualShipmentSectionState extends State<_ManualShipmentSection> {
  final TextEditingController _invoiceController = TextEditingController();

  /// 이미 발송처리된 주문은 입력칸을 감춰 둔다 — [송장 수정하기] 를 눌러야 열린다.
  /// 실수로 정상 송장을 덮어쓰는 경로를 한 번 막는 것이라 미발송 주문에는 영향이 없다.
  bool _editing = false;

  @override
  void dispose() {
    _invoiceController.dispose(); // 누락 시 leak — 상세는 주문마다 새로 만들어진다.
    super.dispose();
  }

  void _onInvoiceChanged(BuildContext context, String? currentError) {
    // 입력을 고치면 직전 전송 실패 문구를 지운다(웹의 onChange 클리어와 같은 규칙).
    if (currentError != null) {
      context.read<ManualShipmentBloc>().add(const SubmitErrorCleared());
    }
    setState(() {}); // 버튼 활성 갱신 (글자마다 emit 하지 않는다)
  }

  @override
  Widget build(BuildContext context) {
    final shipped = isAlreadyShipped(widget.order.status);
    return BlocBuilder<ManualShipmentBloc, ManualShipmentState>(
      builder: (context, state) {
        // ADMIN 이 아님 — 서버가 내린 판정을 그대로 반영한다.
        if (state.optionsForbidden) return const SizedBox.shrink();

        final locked = state.submitting || state.result != null;
        final canSubmit = !locked &&
            state.carrierCode != null &&
            _invoiceController.text.trim().isNotEmpty &&
            state.options.isNotEmpty;
        // 미발송이면 늘 열려 있고, 발송된 건은 [송장 수정하기] 를 누른 뒤에만 열린다.
        final formOpen = !shipped || _editing;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '발송처리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '박스 ${widget.order.externalBoxId ?? '-'} 의 모든 옵션에 같은 운송장번호가 적용됩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (shipped) ...[
                  const SizedBox(height: 8),
                  Text(
                    formOpen
                        ? '이미 발송처리된 주문입니다. 입력한 운송장으로 송장 수정을 요청합니다.'
                        : '이미 발송처리된 주문입니다. 운송장을 고치려면 [송장 수정하기] 를 누르세요.',
                    style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                  ),
                ],
                if (!formOpen) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: locked ? null : () => setState(() => _editing = true),
                    child: const Text('송장 수정하기'),
                  ),
                ],
                if (formOpen) ...[
                const SizedBox(height: 12),
                if (state.loadingOptions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  // 값은 마켓 코드 자체다(D2 개정) — 쿠팡은 택배사 목록 API 가 없어 코드표 전량이 온다.
                  // 서버가 등록 택배사를 맨 위로 정렬해 주므로 여기서 다시 정렬하지 않는다.
                  DropdownButtonFormField<String>(
                    // 목록에 없는 값을 넘기면 Dropdown 이 assert 로 죽는다 — 조회 실패로
                    // options 가 비었는데 직전 선택이 남아 있는 경우를 막는다.
                    value: state.options
                            .any((o) => o.deliveryCompanyCode == state.carrierCode)
                        ? state.carrierCode
                        : null,
                    isExpanded: true, // 코드표가 길다 — 긴 이름이 overflow 하지 않게
                    decoration: const InputDecoration(
                      labelText: '택배사',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: state.options
                        .map((o) => DropdownMenuItem<String>(
                              value: o.deliveryCompanyCode,
                              child: Text(
                                o.registered ? '${o.carrierName} (등록)' : o.carrierName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: locked || state.options.isEmpty
                        ? null
                        : (value) {
                            if (value != null) {
                              context
                                  .read<ManualShipmentBloc>()
                                  .add(CarrierSelected(value));
                            }
                          },
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invoiceController,
                  maxLength: 50, // 형식 검증은 하지 않는다(택배사마다 다르다, D15)
                  enabled: !locked && state.options.isNotEmpty,
                  onChanged: (_) => _onInvoiceChanged(context, state.errorMessage),
                  decoration: const InputDecoration(
                    labelText: '송장번호',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                // 조회 실패와 '등록된 택배사 없음' 은 안내가 다르다 — 합치면 거짓 안내가 된다.
                if (!state.loadingOptions && state.optionsLoadFailed)
                  Row(
                    children: [
                      const Expanded(
                        child: Text('택배사 목록을 불러오지 못했습니다.',
                            style: TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () => context
                            .read<ManualShipmentBloc>()
                            .add(LoadCarrierOptions(widget.order.platform)),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  )
                else if (!state.loadingOptions && state.options.isEmpty)
                  // 쿠팡은 코드표 전량을 내려주므로 여기까지 오면 서버 쪽 문제다.
                  Text(
                    '선택할 수 있는 택배사가 없습니다. 잠시 후 다시 시도해주세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: canSubmit
                      ? () => context.read<ManualShipmentBloc>().add(
                            SubmitManualShipment(
                              orderItemId: widget.order.id,
                              invoiceNumber: _invoiceController.text.trim(),
                            ),
                          )
                      : null,
                  child: state.submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(shipped ? '송장 수정 요청' : '발송처리'),
                ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                ],
                if (state.result != null) ...[
                  const SizedBox(height: 12),
                  ..._buildResult(state.result!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 결과는 인라인으로 남긴다(SnackBar ❌ — 스크롤해서 다시 볼 수 있어야 한다).
  List<Widget> _buildResult(ManualShipmentResult result) {
    final widgets = <Widget>[];
    if (result.succeeded > 0 && result.failed.isEmpty) {
      widgets.add(Text(
        '${result.isUpdateMode ? '송장 수정 요청 완료' : '발송처리 완료'} — '
        '박스 ${result.shipmentBoxId} · ${result.sentLines}건',
        style: TextStyle(fontSize: 13, color: Colors.green[700]),
      ));
    }
    // 실패는 쿠팡 원문(resultCode/message)을 가공 없이 노출한다(D6).
    for (final failed in result.failed) {
      widgets.add(Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${failed.shipmentBoxId} · ${failed.resultCode} · ${failed.message}',
          style: TextStyle(fontSize: 12, color: Colors.red[700]),
        ),
      ));
    }
    return widgets;
  }
}

/// 주문 상세 안 송장 접수시트 섹션 (인라인 확장 — 별도 화면/다이얼로그 없음).
///
/// **용도**: 이 주문 한 건(상태 무관)의 접수시트 rows 를 불러와 라인별 택배수량을 조정하고
/// xlsx 로 저장한다. 진입 시 자동 조회하지 않고 버튼 탭에서만 [LoadOrderSheet] 를 발행한다.
///
/// ⚠️ 개인정보 최소 노출 — 수령인 이름/전화/우편번호/전체주소는 그리지 않는다(단건이라 이름
/// 없이도 라인 식별 가능). 송장시트 목록 화면(다건)이 이름을 보여주는 것과 의도적으로 다르다.
///
/// ⚠️ 권한 게이트는 클라이언트에 두지 않는다 — 서버 403 을 에러 메시지로 노출한다.
/// 플랫폼 버튼 비활성은 표시용 `order.platform` 기준이라 서버(계정 platform) 판정과
/// 어긋날 수 있어 400 메시지 매핑을 함께 둔다.
class _OrderSheetSection extends StatelessWidget {
  final OrderItem order;

  const _OrderSheetSection({required this.order});

  bool get _isCoupang => order.platform == 'COUPANG';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderSheetBloc, OrderSheetState>(
      // transient 상태만 리스닝 — 저장/에러 알림. 중첩 BlocListener 를 두면 두 번 저장된다.
      listenWhen: (prev, curr) =>
          curr is OrderSheetExportSuccess || curr is OrderSheetExportFailure,
      listener: (context, state) {
        if (state is OrderSheetExportSuccess) {
          _saveAndNotify(context, state.bytes);
        } else if (state is OrderSheetExportFailure) {
          _showSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is OrderSheetLoading) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is OrderSheetError) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<OrderSheetBloc>()
                        .add(LoadOrderSheet(order.id)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is OrderSheetLoaded) {
          return _buildSheet(context, state.rows, isExporting: false);
        }
        if (state is OrderSheetExporting) {
          return _buildSheet(context, state.rows, isExporting: true);
        }
        if (state is OrderSheetExportSuccess) {
          return _buildSheet(context, state.rows, isExporting: false);
        }
        if (state is OrderSheetExportFailure) {
          return _buildSheet(context, state.rows, isExporting: false);
        }

        // OrderSheetInitial — 섹션 접힘(버튼만).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isCoupang
                  ? () => context
                      .read<OrderSheetBloc>()
                      .add(LoadOrderSheet(order.id))
                  : null,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('엑셀 다운로드'),
            ),
            if (!_isCoupang) ...[
              const SizedBox(height: 8),
              Text(
                '쿠팡 주문만 지원합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSheet(
    BuildContext context,
    List<ShippingLabelPreviewRow> rows, {
    required bool isExporting,
  }) {
    final isEmpty = rows.isEmpty;

    // Coupang safe numbers expire 48h after delivery and then come
    // back empty. The row cards never render the phone (PII), so this
    // banner is the only signal the user gets. No reissue/refetch button:
    // Coupang has no OpenAPI endpoint for it and a refetch returns the
    // same empty value — reissue happens in WING(반품관리) or via ARS.
    // See PLAN.md D3~D6.
    final hasMissingPhone = rows.any((r) => r.receiverPhone.trim().isEmpty);
    final platformLabel = _platformLabels[order.platform] ?? order.platform;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '송장 접수시트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '주문번호 ${order.externalOrderId} · ${rows.length}건',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (hasMissingPhone) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$platformLabel에서 고객 안심번호를 재발행하십시오.',
                  style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('발송 대상 라인이 없습니다.', textAlign: TextAlign.center),
              )
            else
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OrderSheetRowCard(
                    row: row,
                    onChanged: (parcel) => context.read<OrderSheetBloc>().add(
                          UpdateOrderSheetParcelQuantity(row.rowKey, parcel),
                        ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: isEmpty || isExporting
                  ? null
                  : () => context
                      .read<OrderSheetBloc>()
                      .add(const ExportOrderSheetRequested()),
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: const Text('엑셀 다운로드'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndNotify(BuildContext context, Uint8List bytes) async {
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      // saveAs: 시스템 저장 다이얼로그로 사용자가 위치 선택 → 실제 보이는 파일로 저장.
      // saveFile(bytes) 는 Android 에서 앱 전용 디렉토리에만 써서 사용자가 못 찾는다.
      final path = await FileSaver.instance.saveAs(
        name: '주문목록_${order.externalOrderId}',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      // 사용자가 다이얼로그를 취소하면 null → SnackBar 없이 종료.
      if (path == null || path.isEmpty) return;
      message = '주문목록을 저장했습니다.';
    } catch (_) {
      message = '파일 저장에 실패했습니다.';
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_snackBar(message));
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_snackBar(message));
  }

  // 내비바 오버레이에 가리지 않도록 floating + bottom 여백.
  SnackBar _snackBar(String message) => SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
      );
}

/// 시트 한 라인 카드 — 배송지 앞부분 / 상품명 / 내품수량 + 택배수량 편집(-, 값, +).
/// 송장시트 목록 화면의 `_PreviewRowCard` 와 같은 구조지만 수령인 이름은 제외한다.
class _OrderSheetRowCard extends StatelessWidget {
  final ShippingLabelPreviewRow row;
  final ValueChanged<int> onChanged;

  const _OrderSheetRowCard({required this.row, required this.onChanged});

  /// 배송지 앞부분 = 공백 split 앞 2토큰(예: "울산광역시 중구"). 그 이상은 표시하지 않는다.
  String get _addressHead {
    final parts =
        row.address.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return parts.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _addressHead,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            row.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '내품수량 ${row.quantity}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const Spacer(),
              const Text('택배수량', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              _ParcelStepper(
                quantity: row.parcelQuantity,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 택배수량 -, 값, + 스테퍼. 하한 최소 1(1에서 - 버튼 disabled). 상한 없음.
///
/// ⚠️ `TextFormField` 금지 — 키 입력마다 Loaded 재emit → 재빌드로 커서/입력이 초기화되고
/// 빈 문자열이 1 로 튄다. 송장시트 화면(`_ParcelStepper`)과 편집 UX 를 맞추기 위한 복제본이다
/// (기존 화면의 private 위젯은 변경 금지 대상이라 공유 추출하지 않는다).
class _ParcelStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ParcelStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: quantity <= 1 ? null : () => onChanged(quantity - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
