import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/seller/domain/entities/seller.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../data/models/shipping_label_preview_row.dart';
import '../bloc/shipping_label_preview_bloc.dart';
import '../bloc/shipping_label_preview_event.dart';
import '../bloc/shipping_label_preview_state.dart';

/// 주문목록 확인(Shipping Label V2) 페이지.
///
/// **용도**: 다운로드 전 preview 에서 라인별 택배수량을 편집한 뒤 편집 rows 로 xlsx 를
/// 생성/저장한다. 화면엔 이름+배송지 앞부분+상품명+내품수량+택배수량(편집)만 축약 표시하고,
/// 전화/우편번호/전체주소는 BLoC state 에만 보관(개인정보 미표시)한다.
///
/// **권한**: role 게이트 없음 — 백엔드 403 에 의존(다운로드/발송처리와 동일).
class ShippingLabelPreviewPage extends StatelessWidget {
  const ShippingLabelPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ShippingLabelPreviewBloc>()..add(const LoadPreview()),
      child: const _PreviewView(),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView();

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '주문목록 확인',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.pop(),
      body: BlocConsumer<ShippingLabelPreviewBloc, ShippingLabelPreviewState>(
        // export 성공(transient)만 리스닝 → bytes 저장 + 완료 SnackBar.
        listenWhen: (prev, curr) => curr is PreviewExportSuccess,
        listener: (context, state) => _saveAndNotify(
          context,
          (state as PreviewExportSuccess),
        ),
        builder: (context, state) {
          if (state is PreviewInitial ||
              state is PreviewLoading ||
              state is PreviewExporting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PreviewError) {
            return _ErrorRetry(
              message: state.message,
              onRetry: () =>
                  context.read<ShippingLabelPreviewBloc>().add(const LoadPreview()),
            );
          }

          // PreviewLoaded / PreviewExportSuccess(직후 Loaded 로 복귀) — rows 표시.
          if (state is PreviewLoaded) {
            return _LoadedBody(
              sellers: state.sellers,
              rows: state.rows,
              sellerId: state.sellerId,
            );
          }
          if (state is PreviewExportSuccess) {
            return _LoadedBody(
              sellers: state.sellers,
              rows: state.rows,
              sellerId: state.sellerId,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _saveAndNotify(
    BuildContext context,
    PreviewExportSuccess state,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      // saveAs: 시스템 저장 다이얼로그로 사용자가 위치 선택 → 실제 보이는 파일로 저장.
      // saveFile(bytes) 는 Android 에서 앱 전용 디렉토리에만 써서 다운로드 폴더에
      // 안 보이므로 saveAs 를 사용(다운로드 폴더에 보이게 하기 위함).
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final today = '${now.year}${two(now.month)}${two(now.day)}';
      final path = await FileSaver.instance.saveAs(
        name: '주문목록_$today',
        bytes: state.bytes,
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
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 70),
        ),
      );
  }
}

class _LoadedBody extends StatelessWidget {
  final List<Seller> sellers;
  final List<ShippingLabelPreviewRow> rows;
  final int? sellerId;

  const _LoadedBody({
    required this.sellers,
    required this.rows,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ShippingLabelPreviewBloc>();
    final isEmpty = rows.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 판매자 필터 — 변경 시 새 sellerId 로 재조회(LoadPreview 재dispatch).
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<int?>(
                value: sellerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '판매자',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('전체')),
                  ...sellers.map(
                    (s) => DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text(
                        s.sellerName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => bloc.add(LoadPreview(value)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '총 ${rows.length}건',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isEmpty
                ? const Center(child: Text('발송 대상 주문 없음'))
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight + 16,
                    ),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _PreviewRowCard(
                      row: rows[index],
                      onChanged: (parcel) => bloc.add(
                        UpdateParcelQuantity(rows[index].rowKey, parcel),
                      ),
                    ),
                  ),
          ),
          // 하단 다운로드 버튼 — rows 비면 disabled. nav 겹침 방지 하단 패딩.
          Padding(
            padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isEmpty ? null : () => bloc.add(const ExportRequested()),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('엑셀 다운로드'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 한 라인 카드 — 이름 / 배송지 앞부분 / 상품명 / 내품수량 + 택배수량 편집(-, 값, +).
class _PreviewRowCard extends StatelessWidget {
  final ShippingLabelPreviewRow row;
  final ValueChanged<int> onChanged;

  const _PreviewRowCard({required this.row, required this.onChanged});

  /// 배송지 앞부분 = 공백 split 앞 2토큰(예: "울산광역시 중구").
  String get _addressHead {
    final parts =
        row.address.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return parts.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.receiverName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _addressHead,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(row.productName, style: const TextStyle(fontSize: 13)),
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
      ),
    );
  }
}

/// 택배수량 -, 값, + 스테퍼. 하한 최소 1(1에서 - 버튼 disabled). 상한 없음.
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}
