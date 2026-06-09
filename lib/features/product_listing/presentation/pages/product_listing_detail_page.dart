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

/// 판매상품 상세 페이지
///
/// 프론트 "판매 상품 상세정보"(ProductListingDetailsCard/Table)와 동일하게
/// 상품 기본정보 + 카테고리/물류 정보 + 옵션(판매가/플랫폼 옵션 ID/구성상품)을 표시.
///
/// ⚠️ 수정/삭제 버튼은 현재 Mock 동작이다(실제 API 호출 없음).
///    - 수정: "준비 중" SnackBar 표시
///    - 삭제: 확인 다이얼로그(프론트 ProductListingDeleteDialog와 동일 UX) →
///            확인 시 Mock SnackBar 후 목록으로 복귀
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
      body: BlocBuilder<ProductListingDetailBloc, ProductListingDetailState>(
        builder: (context, state) {
          if (state is ProductListingDetailLoading ||
              state is ProductListingDetailInitial) {
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

          if (state is ProductListingDetailLoaded) {
            final listing = state.listing;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                // 카드가 가로를 꽉 채우도록 stretch (좌우 패딩 16px 동일)
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프론트 헤더 우측의 수정/삭제 버튼 (Mock)
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
                        onPressed: () => _onDelete(context, listing),
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
                  _OptionsCard(options: state.options),
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

  // Mock: 실제 수정 화면은 아직 미구현. 프론트 Phase 5에서 추가 예정.
  void _onEdit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수정 기능은 준비 중입니다. (Mock)'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
      ),
    );
  }

  // Mock: 확인 다이얼로그(프론트와 동일 UX)만 보여주고 실제 삭제 API는 호출하지 않는다.
  Future<void> _onDelete(BuildContext context, ProductListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(
        listingName: '${_platformLabel(listing.platform)} - '
            '${listing.platformProductId}',
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제되었습니다. (Mock)'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
        ),
      );
      context.go(Routes.salesProductsPath);
    }
  }
}

/// 삭제 확인 다이얼로그 (Mock)
///
/// 프론트 ProductListingDeleteDialog와 동일한 문구/구조.
class _DeleteConfirmDialog extends StatelessWidget {
  final String listingName;

  const _DeleteConfirmDialog({required this.listingName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('판매상품 삭제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('정말 삭제하시겠습니까?'),
          const SizedBox(height: 4),
          Text(
            listingName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              '⚠️ 삭제된 데이터는 복구할 수 없습니다.',
              style: TextStyle(fontSize: 13, color: Colors.red[600]),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
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
