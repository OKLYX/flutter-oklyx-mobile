import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_event.dart';
import 'package:flutter_oklyn_mobile/features/category/presentation/bloc/category_list_state.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

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
                      hintText: '카테고리명 검색...',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      context.read<CategoryListBloc>().add(SearchCategoriesRequested(query: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onAddCategoryPressed,
                  child: const Text('카테고리 추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CategoryListBloc, CategoryListState>(
                builder: (context, state) {
                  if (state is CategoryListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CategoryListLoaded) {
                    if (state.categories.isEmpty) {
                      return const Center(
                        child: Text('조회 결과가 없습니다.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.categories.length,
                      itemBuilder: (context, index) {
                        final category = state.categories[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${category.platform} | ${category.createdDate.toString().split('.')[0]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              await context.pushNamed(
                                Routes.categoryDetail,
                                pathParameters: {'id': category.id.toString()},
                              );
                              if (mounted) {
                                context.read<CategoryListBloc>().add(FetchCategoriesRequested());
                              }
                            },
                          ),
                        );
                      },
                    );
                  }

                  if (state is CategoryListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CategoryListBloc>().add(FetchCategoriesRequested());
                            },
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
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
