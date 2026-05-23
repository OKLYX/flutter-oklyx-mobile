import 'package:flutter_oklyn_mobile/features/category/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required int id,
    required String name,
    required String platform,
    required String platformCategoryId,
    int? parentId,
    required DateTime createdDate,
    required DateTime modifiedDate,
  }) : super(
    id: id,
    name: name,
    platform: platform,
    platformCategoryId: platformCategoryId,
    parentId: parentId,
    createdDate: createdDate,
    modifiedDate: modifiedDate,
  );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      platform: json['platform'] as String,
      platformCategoryId: json['platformCategoryId'] as String,
      parentId: json['parentId'] as int?,
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate'] as String) : DateTime.now(),
      modifiedDate: json['modifiedDate'] != null ? DateTime.parse(json['modifiedDate'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'platformCategoryId': platformCategoryId,
      'parentId': parentId,
      'createdDate': createdDate.toIso8601String(),
      'modifiedDate': modifiedDate.toIso8601String(),
    };
  }
}
