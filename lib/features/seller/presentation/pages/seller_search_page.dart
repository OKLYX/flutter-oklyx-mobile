import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_event.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_state.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/widgets/seller_list_item.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

class SellerSearchPage extends StatefulWidget {
  const SellerSearchPage({super.key});

  @override
  State<SellerSearchPage> createState() => _SellerSearchPageState();
}

class _SellerSearchPageState extends State<SellerSearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SellerListBloc>().add(const FetchSellers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddSellerPressed() {
    context.goNamed(Routes.sellerCreate);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '판매자',
      navBarIndex: 2,
      showDrawer: true,
      showAppBarDrawerButton: false,
      body: AppPageBody.slivers(
        slivers: [
          SliverToBoxAdapter(
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '판매자명 검색...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        context
                            .read<SellerListBloc>()
                            .add(SearchSellers(query: value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _onAddSellerPressed,
                    child: const Text('판매자 추가'),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          BlocBuilder<SellerListBloc, SellerListState>(
            builder: (context, state) {
              if (state is SellerListLoading) {
                return const SliverToBoxAdapter(child: AppLoading());
              } else if (state is SellerListInitial) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('조회 버튼을 클릭하여 판매자 정보를 조회해주세요.'),
                  ),
                );
              } else if (state is SellerListEmpty) {
                return const SliverToBoxAdapter(
                  child: AppEmpty('조회 결과가 없습니다.'),
                );
              } else if (state is SellerListError) {
                return SliverToBoxAdapter(
                  child: AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () {
                        context.read<SellerListBloc>().add(const FetchSellers());
                      },
                      child: const Text('다시 시도'),
                    ),
                  ),
                );
              } else if (state is SellerListLoaded) {
                return SliverList.separated(
                  itemCount: state.sellers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final seller = state.sellers[index];
                    return SellerListItem(
                      seller: seller,
                      onTap: () => context.goNamed(
                        Routes.sellerDetail,
                        pathParameters: {'id': seller.id.toString()},
                      ),
                    );
                  },
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }
}
