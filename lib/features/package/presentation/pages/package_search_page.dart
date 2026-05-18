import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_state.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/widgets/package_list_item.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class PackageSearchPage extends StatefulWidget {
  const PackageSearchPage({super.key});

  @override
  State<PackageSearchPage> createState() => _PackageSearchPageState();
}

class _PackageSearchPageState extends State<PackageSearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PackageListBloc>().add(FetchPackages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '상자비',
      navBarIndex: 2,
      showDrawer: false,
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
                      hintText: '상자명 검색...',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      context.read<PackageListBloc>().add(SearchPackages(query: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO Phase 03: Navigate to add package page
                  },
                  child: const Text('상자비 추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<PackageListBloc, PackageListState>(
                builder: (context, state) {
                  if (state is PackageListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is PackageListInitial) {
                    return const Center(
                      child: Text('검색 버튼을 클릭하여 상자비 정보를 조회해주세요.'),
                    );
                  } else if (state is PackageListEmpty) {
                    return const Center(child: Text('조회 결과가 없습니다.'));
                  } else if (state is PackageListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          ElevatedButton(
                            onPressed: () {
                              context.read<PackageListBloc>().add(FetchPackages());
                            },
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is PackageListLoaded) {
                    return ListView.builder(
                      itemCount: state.packages.length,
                      itemBuilder: (context, index) {
                        final pkg = state.packages[index];
                        return PackageListItem(
                          package: pkg,
                          onTap: () => context.goNamed(Routes.packageDetail, pathParameters: {'id': pkg.id.toString()}),
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
