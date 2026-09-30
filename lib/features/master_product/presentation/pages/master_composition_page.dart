import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/master_route_args.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_composition_form.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/entities/product.dart';
import 'package:flutter_oklyn_mobile/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

/// Master **composition change page** (FEATURE_2609_80 / 05 — web
/// `master-products/[id]/composition/components/MasterCompositionContainer.tsx`
/// + `page.tsx` @09208a0).
///
/// **File**: lib/features/master_product/presentation/pages/master_composition_page.dart
///
/// Entry = master detail [구성상품 변경] / product relation panel [구성 변경].
/// Loads the master and the product list (size 1000) together, then hands
/// both to [MasterCompositionForm].
///
/// ⚠️ A page, not a popup (2609_64 D9) — component search + option quantity
///    editing is long work.
/// ⚠️ There is no inactive concept (2609_72) — do not block entry by `active`.
/// ❌ No in-body [← 마스터 상세] button — the app bar back does the same.
class MasterCompositionPage extends StatefulWidget {
  final int masterId;

  const MasterCompositionPage({required this.masterId, super.key});

  @override
  State<MasterCompositionPage> createState() => _MasterCompositionPageState();
}

class _MasterCompositionPageState extends State<MasterCompositionPage> {
  final MasterProductUseCase _useCase = getIt<MasterProductUseCase>();

  MasterProduct? _master;
  List<Product> _products = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MasterCompositionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.masterId != widget.masterId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final masterFuture = _useCase.getMaster(widget.masterId);
    // ⚠️ getProducts returns a page object — the list is `.content`.
    final productsFuture = getIt<GetProductsUseCase>()(
      const GetProductsParams(page: 0, size: 1000),
    );
    await Future.wait<Object>([masterFuture, productsFuture]);
    final masterResult = await masterFuture;
    final productsResult = await productsFuture;
    if (!mounted) {
      return;
    }
    final masterFailure = masterResult.fold((f) => f, (_) => null);
    final productsFailure = productsResult.fold((f) => f, (_) => null);
    final failure = masterFailure ?? productsFailure;
    if (failure != null) {
      setState(() {
        _isLoading = false;
        _error = failureText(failure, '마스터 정보를 불러오지 못했습니다.');
      });
      return;
    }
    setState(() {
      _isLoading = false;
      _master = masterResult.fold((_) => null, (m) => m);
      _products = productsResult.fold((_) => <Product>[], (p) => p.content);
    });
  }

  void _toDetail() {
    context.goNamed(
      Routes.masterProductDetail,
      pathParameters: {'id': '${widget.masterId}'},
      extra: const MasterDetailArgs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final master = _master;
    return ScaffoldWithNavBar(
      title: '구성상품 변경',
      navBarIndex: 2,
      onBackPressed: _toDetail,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          kBottomNavigationBarHeight + 24,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (master != null) ...[
                    Text(master.name, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                  if (_error.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _error,
                        style: TextStyle(fontSize: 14, color: scheme.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_isLoading)
                    const SizedBox(
                      height: 160,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(height: 8),
                            Text('불러오는 중...'),
                          ],
                        ),
                      ),
                    )
                  else if (master != null)
                    MasterCompositionForm(
                      master: master,
                      products: _products,
                      onSaved: _toDetail,
                      onCancel: _toDetail,
                    )
                  else if (_error.isEmpty)
                    Text(
                      '표시할 마스터가 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
