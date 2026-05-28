import '../../domain/entities/commission_rate.dart';
import '../../../category/domain/entities/category.dart';

sealed class CommissionRateDetailState {}

class CommissionRateDetailInitial extends CommissionRateDetailState {}

class CommissionRateDetailLoading extends CommissionRateDetailState {}

class CommissionRateDetailLoaded extends CommissionRateDetailState {
  final CommissionRate commissionRate;
  CommissionRateDetailLoaded(this.commissionRate);
}

class CommissionRateDetailEditing extends CommissionRateDetailState {
  final CommissionRate originalCommissionRate;
  final Map<String, dynamic> editingData;
  final List<Category> availableCategories;
  final Map<String, String?> validationErrors;

  CommissionRateDetailEditing({
    required this.originalCommissionRate,
    required this.editingData,
    required this.availableCategories,
    this.validationErrors = const {},
  });

  CommissionRateDetailEditing copyWith({
    CommissionRate? originalCommissionRate,
    Map<String, dynamic>? editingData,
    List<Category>? availableCategories,
    Map<String, String?>? validationErrors,
  }) {
    return CommissionRateDetailEditing(
      originalCommissionRate: originalCommissionRate ?? this.originalCommissionRate,
      editingData: editingData ?? this.editingData,
      availableCategories: availableCategories ?? this.availableCategories,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class CommissionRateDetailSubmitting extends CommissionRateDetailState {
  final CommissionRate commissionRate;
  CommissionRateDetailSubmitting(this.commissionRate);
}

class CommissionRateDetailUpdateSuccess extends CommissionRateDetailState {
  final CommissionRate commissionRate;
  CommissionRateDetailUpdateSuccess(this.commissionRate);
}

class CommissionRateDetailDeleteSuccess extends CommissionRateDetailState {}

class CommissionRateDetailError extends CommissionRateDetailState {
  final String message;
  CommissionRateDetailError(this.message);
}
