import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock_log_entity.dart';

class StockSearchResultTable extends StatelessWidget {
  final List<StockLogEntity> logs;

  const StockSearchResultTable({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('바코드')),
                Expanded(flex: 1, child: Text('제품명')),
                Expanded(flex: 1, child: Text('입고')),
                Expanded(flex: 1, child: Text('출고')),
                Expanded(flex: 1, child: Text('재고')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) => _buildLogRow(logs[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(StockLogEntity log) {
    final isInStock = log.stockAdd > 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  log.barcodeId,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(log.productName, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  isInStock ? '${log.stockAdd}' : '-',
                  style: TextStyle(
                    color: isInStock ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  !isInStock ? '${log.stockSub}' : '-',
                  style: TextStyle(
                    color: !isInStock ? Colors.red : Colors.grey,
                  ),
                ),
              ),
              Expanded(flex: 1, child: Text('${log.inStock}')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(log.createdDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
