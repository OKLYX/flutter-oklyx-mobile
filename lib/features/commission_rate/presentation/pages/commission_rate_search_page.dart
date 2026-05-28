import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/routes.dart';
import '../bloc/commission_rate_list_bloc.dart';
import '../bloc/commission_rate_list_event.dart';
import '../bloc/commission_rate_list_state.dart';
import '../dialogs/commission_rate_input_dialog.dart';
import '../widgets/commission_rate_list_item.dart';
import '../../../../shared/widgets/scaffold_with_nav_bar.dart';

class CommissionRateSearchPage extends StatefulWidget {
  const CommissionRateSearchPage({super.key});

  @override
  State<CommissionRateSearchPage> createState() => _CommissionRateSearchPageState();
}

class _CommissionRateSearchPageState extends State<CommissionRateSearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CommissionRateListBloc>().add(FetchCommissionRates());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddCommissionRatePressed() {
    showCreateCommissionRateDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '수수료',
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
                      hintText: '플랫폼명 검색...',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        context.read<CommissionRateListBloc>().add(ClearSearch());
                      } else {
                        context.read<CommissionRateListBloc>().add(SearchCommissionRates(query: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onAddCommissionRatePressed,
                  child: const Text('수수료 추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CommissionRateListBloc, CommissionRateListState>(
                builder: (context, state) {
                  if (state is CommissionRateListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CommissionRateListInitial) {
                    return const Center(
                      child: Text('검색 버튼을 클릭하여 수수료 정보를 조회해주세요.'),
                    );
                  }

                  if (state is CommissionRateListEmpty) {
                    return const Center(child: Text('조회 결과가 없습니다.'));
                  }

                  if (state is CommissionRateListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CommissionRateListBloc>().add(FetchCommissionRates());
                            },
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is CommissionRateListLoaded) {
                    return ListView.builder(
                      itemCount: state.commissionRates.length,
                      itemBuilder: (context, index) {
                        final rate = state.commissionRates[index];
                        return CommissionRateListItem(
                          commissionRate: rate,
                          onTap: () {
                            context.goNamed(
                              Routes.commissionRateDetail,
                              pathParameters: {'id': rate.id.toString()},
                            );
                          },
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
