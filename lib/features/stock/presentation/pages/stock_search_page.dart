import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_drawer.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_search_bloc/stock_search_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_search_bloc/stock_search_event.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_search_bloc/stock_search_state.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/widgets/stock_search_result_table.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/widgets/pagination_widget.dart';

class StockSearchPage extends StatelessWidget {
  const StockSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StockSearchBloc>(),
      child: const _StockSearchView(),
    );
  }
}

class _StockSearchView extends StatefulWidget {
  const _StockSearchView();

  @override
  State<_StockSearchView> createState() => _StockSearchViewState();
}

class _StockSearchViewState extends State<_StockSearchView> {
  late final TextEditingController _barcodeController;
  late final TextEditingController _productNameController;
  late DateTime _startDate;
  late DateTime _endDate;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _previousDrawerState = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
    _productNameController = TextEditingController();
    final today = DateTime.now();
    _startDate = today;
    _endDate = today;
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
      if (isOpen != _previousDrawerState) {
        _previousDrawerState = isOpen;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  void _handleSearch(BuildContext context) {
    final params = GetStockLogsParamsEntity(
      barcodeId: _barcodeController.text.isEmpty
          ? null
          : _barcodeController.text,
      productName: _productNameController.text.isEmpty
          ? null
          : _productNameController.text,
      startDate: _startDate,
      endDate: _endDate,
      page: 0,
      size: 20,
    );

    context.read<StockSearchBloc>().add(StockSearchRequested(params));
  }

  Future<void> _pickDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Scaffold(
        key: _scaffoldKey,
        drawerScrimColor: Colors.black.withOpacity(0.3),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('입출고 조회'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchForm(context),
              const SizedBox(height: 24),
              _buildResultsSection(context),
            ],
          ),
        ),
        bottomNavigationBar: SizedBox.shrink(),
        drawer: const AppDrawer(),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Builder(
          builder: (context) {
            final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;

            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 1,
              selectedItemColor: AppColors.brandMain,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.menu,
                    color: isDrawerOpen ? AppColors.brandMain : Colors.black87,
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.checklist),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.notifications),
                  label: '',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                      Navigator.pop(context);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                    setState(() {});
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() {});
                    });
                    break;
                  case 1:
                    context.go(Routes.dashboardPath);
                    break;
                  case 2:
                    context.go(Routes.listToShopPath);
                    break;
                  case 3:
                    context.go(Routes.notificationPath);
                    break;
                }
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _buildSearchForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: '바코드',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: '제품명',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(true),
                    child: Text(
                      '시작: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(false),
                    child: Text(
                      '종료: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<StockSearchBloc, StockSearchState>(
                buildWhen: (previous, current) =>
                    current is StockSearchLoading ||
                    (current is! StockSearchLoading &&
                        previous is StockSearchLoading),
                builder: (context, state) {
                  final isLoading = state is StockSearchLoading;
                  return ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _handleSearch(context),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('조회'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return BlocBuilder<StockSearchBloc, StockSearchState>(
      builder: (context, state) {
        if (state is StockSearchInitial) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('조건을 입력하고 조회 버튼을 클릭하세요'),
              ),
            ),
          );
        }

        if (state is StockSearchLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is StockSearchError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (state is StockSearchLoaded) {
          if (state.logs.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('검색 결과가 없습니다')),
              ),
            );
          }

          return Column(
            children: [
              StockSearchResultTable(logs: state.logs),
              if (state.totalElements > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: PaginationWidget(
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    onPageChanged: (newPage) {
                      context.read<StockSearchBloc>().add(
                        StockSearchPageChanged(newPage),
                      );
                    },
                  ),
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
