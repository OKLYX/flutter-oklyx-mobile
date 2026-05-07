import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/features/stock/presentation/models/stock_in_out_item.dart';

class StockInOutItemTable extends StatefulWidget {
  final List<StockInOutItem> items;
  final Function(int, int) onQuantityChanged;
  final Function(int) onDeletePressed;

  const StockInOutItemTable({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onDeletePressed,
  });

  @override
  State<StockInOutItemTable> createState() => _StockInOutItemTableState();
}

class _StockInOutItemTableState extends State<StockInOutItemTable> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('제품명')),
                Expanded(flex: 1, child: Text('재고')),
                Expanded(flex: 1, child: Text('수량')),
                Expanded(flex: 1, child: Text('작업')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) => _buildItemRow(index),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = widget.items[index];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, overflow: TextOverflow.ellipsis),
                Text(
                  item.barcodeId,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${item.currentStock}')),
          Expanded(
            flex: 1,
            child: SizedBox(
              width: 50,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final newQuantity = int.tryParse(value) ?? item.quantity;
                    widget.onQuantityChanged(index, newQuantity);
                  }
                },
                controller: TextEditingController(text: '${item.quantity}'),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => widget.onDeletePressed(index),
            ),
          ),
        ],
      ),
    );
  }
}
