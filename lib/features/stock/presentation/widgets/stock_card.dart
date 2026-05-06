import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_event.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/bloc/stock_state.dart';

class StockCard extends StatefulWidget {
  final String barcodeId;
  final String productName;

  const StockCard({
    required this.barcodeId,
    required this.productName,
    super.key,
  });

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  late final TextEditingController _quantityController;
  String _selectedType = 'IN';
  bool _isInitialized = false;
  int _currentInStock = 0;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '0');
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      context.read<StockBloc>().add(GetStockRequested(widget.barcodeId));
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final value = _quantityController.text;
    if (value.isEmpty) {
      _quantityController.text = '0';
      return;
    }

    int? parsed = int.tryParse(value);
    if (parsed == null) {
      _quantityController.text = '0';
      return;
    }

    // 음수면 0으로
    if (parsed < 0) {
      _quantityController.text = '0';
      return;
    }

    // 출고일 때 재고보다 크면 재고량으로
    if (_selectedType == 'OUT' && parsed > _currentInStock) {
      _quantityController.text = _currentInStock.toString();
    }
  }

  void _decreaseQuantity() {
    int current = int.tryParse(_quantityController.text) ?? 0;
    int newValue = (current - 1).clamp(0, 999999);
    _quantityController.text = newValue.toString();
  }

  void _increaseQuantity() {
    int current = int.tryParse(_quantityController.text) ?? 0;
    int maxValue = _selectedType == 'OUT' ? _currentInStock : 999999;
    int newValue = (current + 1).clamp(0, maxValue);
    _quantityController.text = newValue.toString();
  }

  void _onSubmit() {
    final quantity = _quantityController.text.trim();
    final parsedQuantity = int.tryParse(quantity);

    if (parsedQuantity == null || parsedQuantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1 이상의 수량을 입력해주세요')),
      );
      return;
    }

    // Validate OUT quantity against current stock
    if (_selectedType == 'OUT' && parsedQuantity > _currentInStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출고 수량을 확인하십시오')),
      );
      return;
    }

    final request = CreateStockRequest(
      barcodeId: widget.barcodeId,
      type: _selectedType,
      quantity: parsedQuantity,
      name: widget.productName,
    );

    context.read<StockBloc>().add(CreateStockRequested(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBloc, StockState>(
      listener: (context, state) {
        if (state is StockSubmitError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is StockSubmitSuccess) {
          final message = _selectedType == 'IN'
              ? '성공적으로 입고되었습니다'
              : '성공적으로 출고되었습니다';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      child: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state is StockLoading) {
            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '재고 관리',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }

          if (state is StockError) {
            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '재고 관리',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('재고 정보를 불러올 수 없습니다: ${state.message}'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<StockBloc>()
                              .add(GetStockRequested(widget.barcodeId));
                        },
                        child: const Text('다시 시도'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final inStock = switch (state) {
            StockLoaded s => s.inStock,
            StockSubmitting s => s.inStock,
            StockSubmitError s => s.inStock,
            StockSubmitSuccess s => s.inStock,
            _ => 0,
          };

          // Update current stock for validation
          _currentInStock = inStock;

          final isLoading = state is StockSubmitting;
          final canOnlyInput = inStock == 0;

          // Reset to IN if no stock and OUT was selected
          if (canOnlyInput && _selectedType == 'OUT') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedType = 'IN';
              });
            });
          }

          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '재고 관리',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('현재 재고: $inStock'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(label: Text('입고'), value: 'IN'),
                            ButtonSegment(label: Text('출고'), value: 'OUT'),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: canOnlyInput
                              ? (newSelection) {
                                  if (newSelection.first == 'OUT') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('출고 가능한 재고가 없습니다'),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      _selectedType = newSelection.first;
                                    });
                                  }
                                }
                              : (newSelection) {
                                  setState(() {
                                    _selectedType = newSelection.first;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: isLoading ? null : _decreaseQuantity,
                        icon: const Icon(Icons.remove),
                        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                        padding: EdgeInsets.zero,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          enabled: !isLoading,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isLoading ? null : _increaseQuantity,
                        icon: const Icon(Icons.add),
                        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onSubmit,
                      child: Text(_selectedType == 'IN' ? '입고' : '출고'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
