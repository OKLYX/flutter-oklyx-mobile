import 'package:equatable/equatable.dart';
import 'package:flutter_oklyn_mobile/features/stock/domain/entities/stock_log_entity.dart';

sealed class StockSearchState extends Equatable {
  const StockSearchState();

  @override
  List<Object?> get props => [];
}

class StockSearchInitial extends StockSearchState {
  const StockSearchInitial();
}

class StockSearchLoading extends StockSearchState {
  const StockSearchLoading();
}

class StockSearchLoaded extends StockSearchState {
  final List<StockLogEntity> logs;
  final int currentPage;
  final int totalElements;
  final int totalPages;

  const StockSearchLoaded({
    required this.logs,
    required this.currentPage,
    required this.totalElements,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [logs, currentPage, totalElements, totalPages];
}

class StockSearchError extends StockSearchState {
  final String message;

  const StockSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
