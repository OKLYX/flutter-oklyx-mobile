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
/// 프론트 "판매상품 상세"(ProductListingDetailsCard/Table)와 동일하게
/// 상품 기본정보 + 카테고리/물류 정보 + 옵션(판매가/마진/마진율) 표시.
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
      title: '판매상품 상세',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              '옵션',
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
                children: const [
                  Expanded(flex: 3, child: _Cell('옵션명', header: true)),
                  Expanded(flex: 2, child: _Cell('판매가', header: true, alignEnd: true)),
                  Expanded(flex: 2, child: _Cell('마진', header: true, alignEnd: true)),
                  Expanded(flex: 2, child: _Cell('마진율', header: true, alignEnd: true)),
                ],
              ),
              const Divider(height: 16),
              ...options.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _Cell(o.optionName)),
                      Expanded(
                        flex: 2,
                        child: _Cell(_formatNumber(o.sellingPrice), alignEnd: true),
                      ),
                      Expanded(
                        flex: 2,
                        child: _Cell(
                          o.margin != null ? _formatNumber(o.margin!) : '-',
                          alignEnd: true,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _Cell(
                          o.marginRate != null
                              ? '${(o.marginRate! * 100).toStringAsFixed(2)}%'
                              : '-',
                          alignEnd: true,
                        ),
                      ),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: header ? FontWeight.w600 : FontWeight.normal,
        color: header ? Colors.black : Colors.grey[800],
      ),
    );
  }
}
