import '../../domain/entities/commission_rate.dart';

class CommissionRateModel extends CommissionRate {
  CommissionRateModel({
    required int id,
    required String platform,
    int? categoryId,
    required double rate,
    required bool isDefault,
  }) : super(
    id: id,
    platform: platform,
    categoryId: categoryId,
    rate: rate,
    isDefault: isDefault,
  );

  factory CommissionRateModel.fromJson(Map<String, dynamic> json) {
    return CommissionRateModel(
      id: json['id'] as int,
      platform: json['platform'] as String,
      categoryId: json['categoryId'] as int?,
      rate: (json['rate'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'categoryId': categoryId,
    'rate': rate,
    'isDefault': isDefault,
  };
}
