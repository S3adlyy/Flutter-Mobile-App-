import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single product line item within a sale.
/// Supports selling in cartons, pieces, or a combination.
class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final String barcode;
  final int piecesPerCarton;

  // Quantities sold
  final int cartonsSold;
  final int piecesSold;

  // Prices
  final double pricePerCarton;
  final double pricePerPiece;

  // Subtotal = (cartonsSold * pricePerCarton) + (piecesSold * pricePerPiece)
  final double subtotal;

  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.piecesPerCarton,
    required this.cartonsSold,
    required this.piecesSold,
    required this.pricePerCarton,
    required this.pricePerPiece,
    required this.subtotal,
  });

  /// Total pieces sold (cartonsSold * piecesPerCarton + piecesSold)
  int get totalPiecesSold => (cartonsSold * piecesPerCarton) + piecesSold;

  factory SaleItemModel.fromMap(Map<String, dynamic> map, String id) {
    return SaleItemModel(
      id: id,
      saleId: map['saleId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      barcode: map['barcode'] ?? '',
      piecesPerCarton: (map['piecesPerCarton'] ?? 1) as int,
      cartonsSold: (map['cartonsSold'] ?? 0) as int,
      piecesSold: (map['piecesSold'] ?? 0) as int,
      pricePerCarton: (map['pricePerCarton'] ?? 0).toDouble(),
      pricePerPiece: (map['pricePerPiece'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'piecesPerCarton': piecesPerCarton,
      'cartonsSold': cartonsSold,
      'piecesSold': piecesSold,
      'pricePerCarton': pricePerCarton,
      'pricePerPiece': pricePerPiece,
      'subtotal': subtotal,
    };
  }

  SaleItemModel copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    String? barcode,
    int? piecesPerCarton,
    int? cartonsSold,
    int? piecesSold,
    double? pricePerCarton,
    double? pricePerPiece,
    double? subtotal,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      piecesPerCarton: piecesPerCarton ?? this.piecesPerCarton,
      cartonsSold: cartonsSold ?? this.cartonsSold,
      piecesSold: piecesSold ?? this.piecesSold,
      pricePerCarton: pricePerCarton ?? this.pricePerCarton,
      pricePerPiece: pricePerPiece ?? this.pricePerPiece,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}