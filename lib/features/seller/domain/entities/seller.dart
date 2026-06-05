import 'package:equatable/equatable.dart';

class Seller extends Equatable {
  final int id;
  final String sellerName;
  final String businessRegistration;
  final String createdDate;
  final String modifiedDate;

  const Seller({
    required this.id,
    required this.sellerName,
    required this.businessRegistration,
    required this.createdDate,
    required this.modifiedDate,
  });

  @override
  List<Object?> get props => [id, sellerName, businessRegistration, createdDate, modifiedDate];
}
