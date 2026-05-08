import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/batch_stock_request_entity.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_in_out_bloc/stock_in_out_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_in_out_bloc/stock_in_out_event.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_in_out_bloc/stock_in_out_state.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/models/stock_in_out_item.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/widgets/stock_in_out_item_table.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_drawer.dart';

class StockInOutPage extends StatelessWidget {
  const StockInOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<StockInOutBloc>(),
      child: const _StockInOutView(),
    );
  }
}

class _StockInOutView extends StatefulWidget {
  const _StockInOutView();

  @override
  State<_StockInOutView> createState() => _StockInOutViewState();
}

class _StockInOutViewState extends State<_StockInOutView> {
  late final ValueNotifier<StockType> _typeNotifier;
  late final TextEditingController _barcodeController;
  late final FocusNode _barcodeFocusNode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _previousDrawerState = false;

  @override
  void initState() {
    super.initState();
    _typeNotifier = ValueNotifier(StockType.IN);
    _barcodeController = TextEditingController();
    _barcodeFocusNode = FocusNode();
    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
      if (isOpen != _previousDrawerState) {
        _previousDrawerState = isOpen;
        if (mounted) {
          setState(() {});
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockInOutBloc>().add(const StockTypeChanged(StockType.IN));
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _typeNotifier.dispose();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _handleBarcodeSearch(BuildContext context, String barcode) {
    final trimmedBarcode = barcode.trim();
    if (trimmedBarcode.isNotEmpty) {
      context.read<StockInOutBloc>().add(BarcodeSearched(trimmedBarcode, ''));
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<StockInOutBloc>().add(ItemRemoved(index));
              Navigator.pop(dialogContext);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Scaffold(
        key: _scaffoldKey,
        drawerScrimColor: Colors.black.withOpacity(0.3),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('입출고 관리'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[100],
        body: BlocListener<StockInOutBloc, StockInOutState>(
          listenWhen: (previous, current) =>
            current is QuantityExceededAlert ||
            current is BarcodeSearchError,
          listener: (context, state) {
            if (state is QuantityExceededAlert || state is BarcodeSearchError) {
              String message = '';
              if (state is QuantityExceededAlert) {
                message = state.message;
              } else if (state is BarcodeSearchError) {
                message = (state as BarcodeSearchError).message;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  margin: const EdgeInsets.only(bottom: 60),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              );
            }
          },
          child: BlocBuilder<StockInOutBloc, StockInOutState>(
            buildWhen: (previous, current) => current is! QuantityExceededAlert,
            builder: (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStockTypeSelector(context),
                  const SizedBox(height: 24),
                  _buildBarcodeInputSection(context),
                  const SizedBox(height: 24),
                  _buildItemsTableSection(context),
                  const SizedBox(height: 24),
                  _buildSubmitButton(context),
                  const SizedBox(height: 16),
                  _buildMessages(context),
                ],
              ),
            ),
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
              selectedItemColor: const Color(0xffffc417),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.menu,
                    color: isDrawerOpen ? const Color(0xffffc417) : Colors.black87,
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

  Widget _buildStockTypeSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<StockType>(
                valueListenable: _typeNotifier,
                builder: (context, type, _) {
                  return ElevatedButton(
                    onPressed: () {
                      _typeNotifier.value = StockType.IN;
                      context.read<StockInOutBloc>().add(
                        const StockTypeChanged(StockType.IN),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          type == StockType.IN ? Colors.blue : Colors.grey[300],
                      foregroundColor:
                          type == StockType.IN ? Colors.white : Colors.black,
                    ),
                    child: const Text('입고'),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueListenableBuilder<StockType>(
                valueListenable: _typeNotifier,
                builder: (context, type, _) {
                  return ElevatedButton(
                    onPressed: () {
                      _typeNotifier.value = StockType.OUT;
                      context.read<StockInOutBloc>().add(
                        const StockTypeChanged(StockType.OUT),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          type == StockType.OUT ? Colors.blue : Colors.grey[300],
                      foregroundColor:
                          type == StockType.OUT ? Colors.white : Colors.black,
                    ),
                    child: const Text('출고'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeInputSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '바코드 스캔',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            BlocListener<StockInOutBloc, StockInOutState>(
              listenWhen: (previous, current) =>
                  current is StockInOutLoaded ||
                  current is BarcodeSearchError,
              listener: (context, state) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _barcodeFocusNode.requestFocus();
                });
              },
              child: BlocBuilder<StockInOutBloc, StockInOutState>(
                buildWhen: (previous, current) =>
                    current is BarcodeSearchLoading ||
                    (current is! BarcodeSearchLoading &&
                        previous is BarcodeSearchLoading),
                builder: (context, state) {
                  final isLoading = state is BarcodeSearchLoading;
                  return SizedBox(
                    height: 56,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          focusColor: Colors.transparent,
                        ),
                      ),
                      child: TextField(
                        controller: _barcodeController,
                        focusNode: _barcodeFocusNode,
                        enabled: !isLoading,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          suffix: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
                        onSubmitted: (value) {
                          _handleBarcodeSearch(context, value);
                          _barcodeController.clear();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableSection(BuildContext context) {
    return BlocBuilder<StockInOutBloc, StockInOutState>(
      buildWhen: (previous, current) =>
          current is StockInOutLoaded || current is StockInOutInitial,
      builder: (context, state) {
        if (state is! StockInOutLoaded) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('추가된 제품이 없습니다')),
            ),
          );
        }

        if (state.items.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('추가된 제품이 없습니다')),
            ),
          );
        }

        return StockInOutItemTable(
          items: state.items,
          onQuantityChanged: (index, newQuantity) {
            context.read<StockInOutBloc>().add(
              QuantityUpdated(index, newQuantity),
            );
          },
          onDeletePressed: (index) {
            _showDeleteConfirmation(context, index);
          },
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<StockInOutBloc, StockInOutState>(
        buildWhen: (previous, current) =>
            current is StockInOutSubmitting ||
            (current is! StockInOutSubmitting &&
                previous is StockInOutSubmitting),
        builder: (context, state) {
          final isSubmitting = state is StockInOutSubmitting;
          return ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () => context.read<StockInOutBloc>().add(
                  const BatchSubmitRequested(),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('일괄 제출'),
          );
        },
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    return BlocBuilder<StockInOutBloc, StockInOutState>(
      buildWhen: (previous, current) =>
          current is StockInOutSubmitSuccess ||
          current is StockInOutSubmitError ||
          current is BarcodeSearchError,
      builder: (context, state) {
        if (state is StockInOutSubmitSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('입출고 완료!'),
                backgroundColor: Colors.green,
              ),
            );
          });
          return const SizedBox.shrink();
        }

        if (state is StockInOutSubmitError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
