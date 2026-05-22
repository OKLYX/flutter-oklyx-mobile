import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int id;
  final String name;
  final String platform;
  final String platformCategoryId;
  final int? parentId;
  final DateTime createdDate;
  final DateTime modifiedDate;

  const Category({
    required this.id,
    required this.name,
    required this.platform,
    required this.platformCategoryId,
    this.parentId,
    required this.createdDate,
    required this.modifiedDate,
  });

  @override
  List<Object?> get props => [id, name, platform, platformCategoryId, parentId, createdDate, modifiedDate];
}
