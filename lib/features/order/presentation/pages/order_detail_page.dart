import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/shipping_label/data/models/shipping_label_preview_row.dart';
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
/// 플랫폼 / 주문번호 / 박스 ID / 아이템 ID / 상품명 /
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

  // 송장 접수시트 섹션이 OrderSheetBloc 을 필요로 하므로 BuildContext 를 받는다.
  // order == null 분기는 조회할 order.id 가 없어 BlocProvider 자체를 만들지 않는다.
  Widget _buildContent(BuildContext context, OrderItem o) {
    return BlocProvider<OrderSheetBloc>(
      create: (_) => getIt<OrderSheetBloc>(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              title: '기본 정보',
              rows: [
                _InfoRow('플랫폼', o.platform),
                _InfoRow('주문번호', o.externalOrderId),
                _InfoRow('박스 ID', o.externalBoxId ?? '-'),
                _InfoRow('아이템 ID', o.externalItemId),
                _InfoRow('상품명', o.itemName ?? '-'),
                _InfoRow('상태', o.status),
              ],
            ),
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
                _InfoRow('결제일', _formatDate(o.paidAt)),
                _InfoRow('마켓 계정 ID', '${o.marketplaceAccountId}'),
              ],
            ),
            const SizedBox(height: 12),
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

/// ISO LocalDateTime → 'yyyy-MM-dd HH:mm'. null/파싱 실패 시 '-' 또는 원본 반환.
String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
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
