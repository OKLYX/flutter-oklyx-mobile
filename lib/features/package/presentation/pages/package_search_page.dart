import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_create_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_event.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/bloc/package_list_state.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/dialogs/package_input_dialog.dart';
import 'package:flutter_oklyn_mobile/features/package/presentation/widgets/package_list_item.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_page_body.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';

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

  void _onAddPackagePressed() {
    context.read<PackageCreateBloc>().add(ResetCreateForm());

    showDialog(
      context: context,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: context.read<PackageCreateBloc>(),
          ),
          BlocProvider.value(
            value: context.read<PackageListBloc>(),
          ),
        ],
        child: PackageInputDialog(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '상자비',
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
                        hintText: '상자명 검색...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        context
                            .read<PackageListBloc>()
                            .add(SearchPackages(query: value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _onAddPackagePressed,
                    child: const Text('상자비 추가'),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          BlocBuilder<PackageListBloc, PackageListState>(
            builder: (context, state) {
              if (state is PackageListLoading) {
                return const SliverToBoxAdapter(child: AppLoading());
              } else if (state is PackageListInitial) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('검색 버튼을 클릭하여 상자비 정보를 조회해주세요.'),
                  ),
                );
              } else if (state is PackageListEmpty) {
                return const SliverToBoxAdapter(
                  child: AppEmpty('조회 결과가 없습니다.'),
                );
              } else if (state is PackageListError) {
                return SliverToBoxAdapter(
                  child: AppErrorBox(
                    message: state.message,
                    action: FilledButton(
                      onPressed: () {
                        context.read<PackageListBloc>().add(FetchPackages());
                      },
                      child: const Text('다시 시도'),
                    ),
                  ),
                );
              } else if (state is PackageListLoaded) {
                return SliverList.separated(
                  itemCount: state.packages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final pkg = state.packages[index];
                    return PackageListItem(
                      package: pkg,
                      onTap: () => context.goNamed(Routes.packageDetail, pathParameters: {'id': pkg.id.toString()}),
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
