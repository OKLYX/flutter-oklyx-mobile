import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_list_bloc.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_list_event.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/bloc/carrier_rate_list_state.dart';
import 'package:flutter_oklyn_mobile/features/carrier_rate/presentation/widgets/carrier_rate_list_item.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/scaffold_with_nav_bar.dart';

class CarrierRateSearchPage extends StatefulWidget {
  const CarrierRateSearchPage({super.key});

  @override
  State<CarrierRateSearchPage> createState() => _CarrierRateSearchPageState();
}

class _CarrierRateSearchPageState extends State<CarrierRateSearchPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CarrierRateListBloc>().add(FetchCarrierRates());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddCarrierRatePressed() {
    // Phase 04: Open create/edit dialog
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(
      title: '택배비',
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
                      hintText: '배송사명 검색...',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      context.read<CarrierRateListBloc>().add(SearchCarrierRates(query: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onAddCarrierRatePressed,
                  child: const Text('택배비 추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CarrierRateListBloc, CarrierRateListState>(
                builder: (context, state) {
                  if (state is CarrierRateListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CarrierRateListInitial) {
                    return const Center(
                      child: Text('검색 버튼을 클릭하여 택배비 정보를 조회해주세요.'),
                    );
                  }

                  if (state is CarrierRateListEmpty) {
                    return const Center(child: Text('조회 결과가 없습니다.'));
                  }

                  if (state is CarrierRateListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CarrierRateListBloc>().add(FetchCarrierRates());
                            },
                            child: const Text('재시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is CarrierRateListLoaded) {
                    return ListView.builder(
                      itemCount: state.carrierRates.length,
                      itemBuilder: (context, index) {
                        final rate = state.carrierRates[index];
                        return CarrierRateListItem(
                          carrierRate: rate,
                          onTap: () {
                            // Phase 04: Navigate to detail/edit page
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
