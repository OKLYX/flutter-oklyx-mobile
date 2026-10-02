import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/logic/market_source.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/market_source_card.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_create_form.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_section_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/result_toast.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';

// Sections while the product-relation overview is on (R-g).
const String _secProducts = 'products';
const String _secMaster = 'master';

// Market lookup state of "new master" mode (2609_79). idle = not market mode.
enum _MarketStatus { idle, loading, error, ready }

/// 「판매 상품 관리 마스터」 = master **create** page (FEATURE_2609_80 / 10) —
/// port of web `master-products/new/page.tsx` +
/// `components/MasterProductCreateContainer.tsx` (@09208a0).
///
/// **File**: lib/features/master_product/presentation/pages/master_create_page.dart
///
/// [args] = null when opened from the drawer (no preselected products, not
/// market mode). Market mode = seller id > 0 and platform / platform product
/// id not blank (same condition as the web): the marketplace product is
/// looked up once and the form is drawn only after it arrives (the lookup
/// result is its initial value).
///
/// Top of the body: overview off = a single 「상품 관계」 chip (the form only);
/// on = section row `물품 · 마스터` (no sales-channel section before saving —
/// D69). Turning it on shows 물품 first, turning it off shows the form (R25).
///
/// There is no completion screen (UX S3): a save shows a toast and goes to
/// the master detail with the overview on — this page leaves the stack
/// (R17).
///
/// ⚠️ The body is a single scroll (not a lazy list) so the offstage product
///    panel and the form are never disposed (R9 — unsaved input).
/// ❌ No product registration in the product panel (R-g).
class MasterCreatePage extends StatefulWidget {
  final MasterCreateArgs? args;

  const MasterCreatePage({super.key, this.args});

  @override
  State<MasterCreatePage> createState() => _MasterCreatePageState();
}

class _MasterCreatePageState extends State<MasterCreatePage> {
  bool _overviewOpen = false;
  String _section = _secMaster;

  _MarketStatus _status = _MarketStatus.idle;
  String _marketError = '';
  MarketSource? _market;

  bool get _isMarketMode {
    final args = widget.args;
    return args != null &&
        args.sellerId > 0 &&
        args.platform.trim().isNotEmpty &&
        args.platformProductId.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_isMarketMode) {
      _status = _MarketStatus.loading;
      unawaited(_loadMarket());
    }
  }

  Future<void> _loadMarket() async {
    final args = widget.args!;
    final sellerId = args.sellerId;
    final platform = args.platform.trim();
    final platformProductId = args.platformProductId.trim();
    setState(() => _status = _MarketStatus.loading);
    final result = await getIt<MasterProductUseCase>().masterFromChannelPreview(
      sellerId: sellerId,
      platform: platform,
      platformProductId: platformProductId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      result.fold(
        (f) {
          _status = _MarketStatus.error;
          _marketError = failureText(f, '마켓 상품을 조회하지 못했습니다.');
        },
        (preview) {
          _status = _MarketStatus.ready;
          _market = MarketSource(
            sellerId: sellerId,
            platform: platform,
            platformProductId: platformProductId,
            preview: preview,
          );
        },
      );
    });
  }

  void _handleCreated(int masterId) {
    showSuccessToast(context, '마스터를 만들었습니다.');
    context.goNamed(
      Routes.masterProductDetail,
      pathParameters: {'id': '$masterId'},
      extra: const MasterDetailArgs(openOverview: true),
    );
  }

  void _handleCreatedWithWarning(int masterId, String warning) {
    // The master exists — the toast is the same; the detail banner tells
    // what is left to fill in.
    showSuccessToast(context, '마스터를 만들었습니다.');
    context.goNamed(
      Routes.masterProductDetail,
      pathParameters: {'id': '$masterId'},
      extra: MasterDetailArgs(openOverview: true, notice: warning),
    );
  }

  void _handleCancel() => context.go(Routes.masterProductsPath);

  void _toggleOverview() {
    setState(() {
      _overviewOpen = !_overviewOpen;
      // R25: on = the product panel just opened; off = the form.
      _section = _overviewOpen ? _secProducts : _secMaster;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final market = _market;
    final relationChip = FilterChip(
      label: const Text('상품 관계'),
      selected: _overviewOpen,
      onSelected: (_) => _toggleOverview(),
    );
    return ScaffoldWithNavBar(
      title: '판매 상품 관리 마스터',
      navBarIndex: 2,
      showAppBarDrawerButton: false,
      body: AppPageBody.scroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_overviewOpen)
              MasterSectionBar(
                items: const [
                  MasterSectionItem(key: _secProducts, label: '물품'),
                  MasterSectionItem(key: _secMaster, label: '마스터'),
                ],
                selected: _section,
                onSelected: (key) => setState(() => _section = key),
                trailing: relationChip,
              )
            else
              Align(alignment: Alignment.centerLeft, child: relationChip),
            const SizedBox(height: 12),
            if (_status == _MarketStatus.loading)
              const SizedBox(
                height: 128,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('마켓 상품을 불러오는 중...'),
                    ],
                  ),
                ),
              ),
            if (_status == _MarketStatus.error)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _marketError,
                      style: TextStyle(fontSize: 14, color: scheme.error),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () =>
                          context.go(Routes.masterProductFromMarketPath),
                      child: const Text(
                        '마켓 상품으로 시작으로 돌아가기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_status == _MarketStatus.ready && market != null) ...[
              MarketSourceCard(market: market),
              const SizedBox(height: 16),
            ],
            if (_status == _MarketStatus.idle || _status == _MarketStatus.ready)
              // 🔴 Market values are the form's initial value — a different
              // (or no) starting product remounts the form.
              KeyedSubtree(
                key: ValueKey(
                  market != null
                      ? 'market-${market.platformProductId}'
                      : 'plain',
                ),
                child: MasterCreateForm(
                  initialProductIds: widget.args?.productIds ?? const [],
                  overviewOpen: _overviewOpen && _section == _secProducts,
                  onCreated: _handleCreated,
                  onCreatedWithWarning: _handleCreatedWithWarning,
                  onCancel: _handleCancel,
                  market: market,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
