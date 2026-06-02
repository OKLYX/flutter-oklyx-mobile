import 'package:equatable/equatable.dart';

class Seller extends Equatable {
  final int id;
  final String sellerName;
  final String businessRegistration;

  const Seller({
    required this.id,
    required this.sellerName,
    required this.businessRegistration,
  });

  @override
  List<Object?> get props => [id, sellerName, businessRegistration];
}
