import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../../domain/entities/product_listing.dart';
import '../bloc/product_listing_detail_bloc.dart';
import '../bloc/product_listing_detail_event.dart';
import '../bloc/product_listing_detail_state.dart';
import '../product_listing_refresh.dart';

/// 판매상품 상세 페이지
///
/// 프론트 "판매 상품 상세정보"(ProductListingDetailsCard/Table)와 동일하게
/// 상품 기본정보 + 카테고리/물류 정보 + 옵션(판매가/플랫폼 옵션 ID/구성상품)을 표시.
///
/// 수정/삭제 버튼은 프론트 상세 페이지와 동일하게 동작한다:
///    - 수정: 수정 페이지(ProductListingEditPage)로 이동 → 폼 프리필 후 update
///    - 삭제: 확인 다이얼로그(프론트 ProductListingDeleteDialog와 동일 UX) →
///            확인 시 delete API 호출 → 성공 시 목록으로 복귀
class ProductListingDetailPage extends StatelessWidget {
  final int id;

  const ProductListingDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ProductListingDetailBloc>()..add(LoadProductListingDetail(id)),
      child: _ProductListingDetailView(id: id),
    );
  }
}

class _ProductListingDetailView extends StatelessWidget {
  final int id;

  const _ProductListingDetailView({required this.id});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매 상품 상세정보',
      navBarIndex: 2,
      showDrawer: true,
      onBackPressed: () => context.go(Routes.salesProductsPath),
      body: BlocConsumer<ProductListingDetailBloc, ProductListingDetailState>(
        listener: (context, state) {
          if (state is ProductListingDetailDeleteSuccess) {
            // 조회 페이지가 삭제를 반영하도록 갱신 신호 발행 후 목록으로 이동
            notifyProductListingChanged();
            context.go(Routes.salesProductsPath);
          } else if (state is ProductListingDetailDeleteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProductListingDetailLoading ||
              state is ProductListingDetailInitial ||
              state is ProductListingDetailDeleteSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductListingDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ProductListingDetailBloc>()
                        .add(LoadProductListingDetail(id)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 삭제 중/실패 상태도 기존 데이터를 보관하므로 동일하게 내용을 렌더링한다
          // (삭제 진행/오류 표시는 다이얼로그가 담당).
          ProductListing? listing;
          List<ProductListingOption> options = const [];
          if (state is ProductListingDetailLoaded) {
            listing = state.listing;
            options = state.options;
          } else if (state is ProductListingDetailDeleting) {
            listing = state.listing;
            options = state.options;
          } else if (state is ProductListingDetailDeleteFailure) {
            listing = state.listing;
            options = state.options;
          }

          if (listing != null) {
            // 클로저(버튼 콜백)에서 non-null 승격을 유지하기 위해 final 로 고정.
            final ProductListing loaded = listing;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                // 카드가 가로를 꽉 채우도록 stretch (좌우 패딩 16px 동일)
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프론트 헤더 우측의 수정/삭제 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _onEdit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('수정'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _onDelete(context, loaded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: '기본 정보',
                    rows: [
                      _InfoRow('플랫폼', _platformLabel(listing.platform)),
                      _InfoRow('상품 ID', listing.platformProductId),
                      _InfoRow('상품명', listing.name),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: '카테고리 · 물류',
                    rows: [
                      _InfoRow('카테고리', listing.categoryName ?? '-'),
                      _InfoRow('판매자', listing.sellerName ?? '-'),
                      _InfoRow('배송사', listing.carrierName ?? '-'),
                      _InfoRow('패키지', listing.packageType ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _OptionsCard(options: options),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _platformLabel(String platform) {
    const labels = {
      'COUPANG': '쿠팡',
      'GMARKET': '지마켓',
      'AUCTION': '옥션',
      'SMARTSTORE': '스마트스토어',
    };
    return labels[platform] ?? platform;
  }

  // 수정 페이지로 이동 (프론트 router.push(EDIT)와 동일). 뒤로가기 시 상세로 복귀.
  void _onEdit(BuildContext context) {
    context.push(Routes.salesProductsEditRoute(id));
  }

  // 삭제 확인 다이얼로그 표시(상자비/택배비 상세와 동일한 UI).
  // 확인 시 다이얼로그를 닫고 BLoC delete 이벤트 발행 →
  // 성공/실패 처리는 페이지 상단의 BlocListener가 담당.
  void _onDelete(BuildContext context, ProductListing listing) {
    final bloc = context.read<ProductListingDetailBloc>();
    showDialog(
      context: context,
      builder: (ctx) => _DeleteConfirmationDialog(
        listingName: '${_platformLabel(listing.platform)} - '
            '${listing.platformProductId}',
        onConfirm: () {
          Navigator.pop(ctx);
          bloc.add(DeleteProductListing(listing.id));
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

/// 삭제 확인 다이얼로그
///
/// 상자비(PackageDetailPage)·택배비(CarrierRateDetailPage) 상세의 삭제 모달과
/// 동일한 UI/구조: 간단한 AlertDialog + 취소(TextButton)/삭제(빨간 FilledButton).
class _DeleteConfirmationDialog extends StatelessWidget {
  final String listingName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.listingName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('판매상품 삭제'),
      content: Text('$listingName을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}

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

/// 옵션 및 구성상품 카드
///
/// 프론트 ProductListingDetailsTable과 동일한 컬럼:
/// 옵션명 / 판매가 / 플랫폼 옵션 ID / 구성상품(상품명 × 수량개)
class _OptionsCard extends StatelessWidget {
  final List<ProductListingOption> options;

  const _OptionsCard({required this.options});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 옵션 및 구성상품',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (options.isEmpty)
              Text(
                '등록된 옵션이 없습니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(flex: 3, child: _Cell('옵션명', header: true)),
                  Expanded(
                      flex: 2,
                      child: _Cell('판매가', header: true, alignEnd: true)),
                  Expanded(flex: 3, child: _Cell('플랫폼 옵션 ID', header: true)),
                  Expanded(flex: 3, child: _Cell('구성상품', header: true)),
                ],
              ),
              const Divider(height: 16),
              ...options.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _Cell(o.optionName)),
                      Expanded(
                        flex: 2,
                        child: _Cell('${_formatNumber(o.sellingPrice)}원',
                            alignEnd: true),
                      ),
                      Expanded(
                        flex: 3,
                        child: _Cell(o.platformOptionId ?? '-'),
                      ),
                      Expanded(
                          flex: 3, child: _ProductsCell(products: o.products)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final negative = str.startsWith('-');
    final digits = negative ? str.substring(1) : str;
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }
}

/// 구성상품 셀: 상품명 × 수량개 형태로 세로 나열 (프론트와 동일)
class _ProductsCell extends StatelessWidget {
  final List<ProductListingProduct>? products;

  const _ProductsCell({required this.products});

  @override
  Widget build(BuildContext context) {
    final items = products ?? const [];
    if (items.isEmpty) {
      return Text(
        '-',
        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${p.productName} × ${p.quantity}개',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool header;
  final bool alignEnd;

  const _Cell(this.text, {this.header = false, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: TextStyle(
        fontSize: 13,
        fontWeight: header ? FontWeight.w600 : FontWeight.normal,
        color: header ? Colors.black : Colors.grey[800],
      ),
    );
  }
}
