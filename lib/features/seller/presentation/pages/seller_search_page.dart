import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_event.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/bloc/seller_list_state.dart';
import 'package:flutter_oklyn_mobile/features/seller/presentation/widgets/seller_list_item.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '판매자명 검색...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      context.read<SellerListBloc>().add(SearchSellers(query: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onAddSellerPressed,
                  child: const Text('판매자 추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<SellerListBloc, SellerListState>(
                builder: (context, state) {
                  if (state is SellerListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SellerListInitial) {
                    return const Center(
                      child: Text('조회 버튼을 클릭하여 판매자 정보를 조회해주세요.'),
                    );
                  } else if (state is SellerListEmpty) {
                    return const Center(child: Text('조회 결과가 없습니다.'));
                  } else if (state is SellerListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SellerListBloc>().add(const FetchSellers());
                            },
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is SellerListLoaded) {
                    return ListView.separated(
                      itemCount: state.sellers.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
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
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
