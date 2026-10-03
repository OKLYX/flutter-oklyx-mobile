import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_search_field.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryListBloc>().add(FetchCategoriesRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddCategoryPressed() async {
    final result = await context.pushNamed(Routes.categoryCreate);
    if (result == true) {
      if (mounted) {
        context.read<CategoryListBloc>().add(FetchCategoriesRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '카테고리',
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
                    child: AppSearchField(
                      controller: _searchController,
                      hintText: '카테고리명 검색...',
                      onChanged: (value) {
                        context
                            .read<CategoryListBloc>()
                            .add(SearchCategoriesRequested(query: value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _onAddCategoryPressed,
                    child: const Text('카테고리 추가'),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          BlocBuilder<CategoryListBloc, CategoryListState>(
            builder: (context, state) {
              if (state is CategoryListLoading) {
                return const SliverToBoxAdapter(child: AppLoading());
              }

              if (state is CategoryListLoaded) {
                if (state.categories.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: AppEmpty('조회 결과가 없습니다.'),
                  );
                }
                return SliverList.separated(
                  itemCount: state.categories.length,
                  separatorBuilder: (context, index) => const AppRowGap(),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return AppCard.row(
                      onTap: () async {
                        await context.pushNamed(
                          Routes.categoryDetail,
                          pathParameters: {'id': category.id.toString()},
                        );
                        if (mounted) {
                          context
                              .read<CategoryListBloc>()
                              .add(FetchCategoriesRequested());
                        }
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${category.platform} | ${category.createdDate.toString().split('.')[0]}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                );
              }

              if (state is CategoryListError) {
                return SliverToBoxAdapter(
                  child: AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () {
                        context
                            .read<CategoryListBloc>()
                            .add(FetchCategoriesRequested());
                      },
                      child: const Text('다시 시도'),
                    ),
                  ),
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
