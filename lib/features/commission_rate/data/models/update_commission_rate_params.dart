class UpdateCommissionRateParams {
  final String? platform;
  final int? categoryId;
  final double? rate;

  UpdateCommissionRateParams({
    this.platform,
    this.categoryId,
    this.rate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (platform != null) map['platform'] = platform;
    if (categoryId != null) map['categoryId'] = categoryId;
    if (rate != null) map['rate'] = rate;
    return map;
  }
}
