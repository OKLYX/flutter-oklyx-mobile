import 'package:equatable/equatable.dart';

/// Result of reading a barcode from an uploaded image
/// (`POST /api/admin/products/barcode-scan`).
///
/// [barcode] is null when the server found no readable barcode.
/// The image itself is never stored by the server.
class BarcodeScanResult extends Equatable {
  final String? barcode;
  final String? format;

  const BarcodeScanResult({this.barcode, this.format});

  @override
  List<Object?> get props => [barcode, format];
}
