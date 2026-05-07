import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/get_stock_logs_params_entity.dart';

sealed class StockSearchEvent extends Equatable {
  const StockSearchEvent();

  @override
  List<Object?> get props => [];
}

class StockSearchRequested extends StockSearchEvent {
  final GetStockLogsParamsEntity params;

  const StockSearchRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class StockSearchPageChanged extends StockSearchEvent {
  final int newPage;

  const StockSearchPageChanged(this.newPage);

  @override
  List<Object?> get props => [newPage];
}
