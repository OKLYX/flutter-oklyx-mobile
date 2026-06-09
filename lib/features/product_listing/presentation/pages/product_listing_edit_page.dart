import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import '../bloc/product_listing_create_bloc.dart';
import '../bloc/product_listing_detail_bloc.dart';
import '../bloc/product_listing_detail_event.dart';
import '../bloc/product_listing_detail_state.dart';
import 'product_listing_register_page.dart';

/// 판매상품 수정 페이지.
///
/// 프론트 "판매상품 상세정보 → 수정 버튼" 흐름과 동일하게 동작한다:
/// 1) 상세(getById)를 먼저 로드해 기존 데이터를 가져온 뒤
/// 2) 그 데이터로 [ProductListingRegisterPage]를 수정 모드(editListing)로 띄운다.
///    → 등록 폼 UI/검증/옵션·마진 로직을 그대로 재사용하고, 제출 시 update를 호출한다.
///
/// 상세 로드 BLoC([ProductListingDetailBloc])과 폼 BLoC([ProductListingCreateBloc])을
/// 함께 제공한다. 폼 BLoC의 lookup 데이터 로드/프리필은 RegisterPage가 마운트된 뒤
/// 자체적으로 수행한다.
class ProductListingEditPage extends StatelessWidget {
  final int id;

  const ProductListingEditPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductListingCreateBloc>(
          create: (_) => GetIt.instance<ProductListingCreateBloc>(),
        ),
        BlocProvider<ProductListingDetailBloc>(
          create: (_) => GetIt.instance<ProductListingDetailBloc>()
            ..add(LoadProductListingDetail(id)),
        ),
      ],
      child: BlocBuilder<ProductListingDetailBloc, ProductListingDetailState>(
        builder: (context, state) {
          if (state is ProductListingDetailLoaded) {
            return ProductListingRegisterPage(editListing: state.listing);
          }

          if (state is ProductListingDetailError) {
            return ScaffoldWithNavBar(
              title: '판매상품 수정',
              navBarIndex: 2,
              showDrawer: true,
              onBackPressed: () => context.go(Routes.salesProductsPath),
              body: Center(
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
              ),
            );
          }

          return ScaffoldWithNavBar(
            title: '판매상품 수정',
            navBarIndex: 2,
            showDrawer: true,
            onBackPressed: () => context.go(Routes.salesProductsPath),
            body: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
