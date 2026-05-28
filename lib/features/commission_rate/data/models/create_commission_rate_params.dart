class CreateCommissionRateParams {
  final String platform;
  final int? categoryId;
  final double rate;

  CreateCommissionRateParams({
    required this.platform,
    this.categoryId,
    required this.rate,
  });

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'categoryId': categoryId,
    'rate': rate,
  };
}
