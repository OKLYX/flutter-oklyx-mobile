import 'package:equatable/equatable.dart';

class GetStockResponse extends Equatable {
  final String barcodeId;
  final int inStock;

  const GetStockResponse({
    required this.barcodeId,
    required this.inStock,
  });

  factory GetStockResponse.fromJson(Map<String, dynamic> json) {
    return GetStockResponse(
      barcodeId: json['barcodeId'] as String,
      inStock: json['inStock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcodeId': barcodeId,
      'inStock': inStock,
    };
  }

  @override
  List<Object?> get props => [barcodeId, inStock];
}

class CreateStockRequest extends Equatable {
  final String barcodeId;
  final String type;
  final int quantity;
  final String name;

  const CreateStockRequest({
    required this.barcodeId,
    required this.type,
    required this.quantity,
    required this.name,
  });

  factory CreateStockRequest.fromJson(Map<String, dynamic> json) {
    return CreateStockRequest(
      barcodeId: json['barcodeId'] as String,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcodeId': barcodeId,
      'type': type,
      'quantity': quantity,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [barcodeId, type, quantity, name];
}

class CreateStockResponse extends Equatable {
  final int stockId;
  final String barcodeId;
  final int inStock;
  final String name;
  final int stockAdd;
  final int stockSub;
  final String createdDate;

  const CreateStockResponse({
    required this.stockId,
    required this.barcodeId,
    required this.inStock,
    required this.name,
    required this.stockAdd,
    required this.stockSub,
    required this.createdDate,
  });

  factory CreateStockResponse.fromJson(Map<String, dynamic> json) {
    return CreateStockResponse(
      stockId: json['stockId'] as int,
      barcodeId: json['barcodeId'] as String,
      inStock: json['inStock'] as int,
      name: json['name'] as String,
      stockAdd: json['stockAdd'] as int,
      stockSub: json['stockSub'] as int,
      createdDate: json['createdDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockId': stockId,
      'barcodeId': barcodeId,
      'inStock': inStock,
      'name': name,
      'stockAdd': stockAdd,
      'stockSub': stockSub,
      'createdDate': createdDate,
    };
  }

  @override
  List<Object?> get props => [
    stockId,
    barcodeId,
    inStock,
    name,
    stockAdd,
    stockSub,
    createdDate,
  ];
}
