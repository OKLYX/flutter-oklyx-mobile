import '../../domain/entities/commission_rate.dart';
import '../../../category/domain/entities/category.dart';

sealed class CommissionRateCreateState {}

class CommissionRateCreateInitial extends CommissionRateCreateState {
  final String platform;
  final int? selectedCategoryId;
  final String rate;
  final List<Category> availableCategories;
  final bool isLoadingCategories;
  final bool isSubmitting;
  final bool isValid;

  CommissionRateCreateInitial({
    this.platform = '',
    this.selectedCategoryId,
    this.rate = '',
    this.availableCategories = const [],
    this.isLoadingCategories = false,
    this.isSubmitting = false,
    this.isValid = false,
  });

  CommissionRateCreateInitial copyWith({
    String? platform,
    int? selectedCategoryId,
    String? rate,
    List<Category>? availableCategories,
    bool? isLoadingCategories,
    bool? isSubmitting,
    bool? isValid,
  }) {
    return CommissionRateCreateInitial(
      platform: platform ?? this.platform,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      rate: rate ?? this.rate,
      availableCategories: availableCategories ?? this.availableCategories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
    );
  }
}

class CommissionRateCreateLoading extends CommissionRateCreateState {}

class CommissionRateCreateSuccess extends CommissionRateCreateState {
  final CommissionRate commissionRate;

  CommissionRateCreateSuccess(this.commissionRate);
}

class CommissionRateCreateError extends CommissionRateCreateState {
  final String message;

  CommissionRateCreateError(this.message);
}
