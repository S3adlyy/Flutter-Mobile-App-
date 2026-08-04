import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single product line item within a purchase.
/// Each item tracks carton-based quantities and pricing.
class PurchaseItemModel {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final String barcode;
  final int cartonQuantity; // Number of cartons purchased
  final int piecesPerCarton; // How many pieces in each carton
  final double pricePerCarton;
  final double pricePerPiece; // Derived: pricePerCarton / piecesPerCarton
  final DateTime? expirationDate;
  final DateTime? manufacturingDate;
  final double totalPrice; // cartonQuantity * pricePerCarton

  const PurchaseItemModel({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.cartonQuantity,
    required this.piecesPerCarton,
    required this.pricePerCarton,
    required this.pricePerPiece,
    this.expirationDate,
    this.manufacturingDate,
    required this.totalPrice,
  });

  /// Total pieces purchased (cartonQuantity * piecesPerCarton)
  int get totalPieces => cartonQuantity * piecesPerCarton;

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseItemModel(
      id: id,
      purchaseId: map['purchaseId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      barcode: map['barcode'] ?? '',
      cartonQuantity: (map['cartonQuantity'] ?? 0) as int,
      piecesPerCarton: (map['piecesPerCarton'] ?? 1) as int,
      pricePerCarton: (map['pricePerCarton'] ?? 0).toDouble(),
      pricePerPiece: (map['pricePerPiece'] ?? 0).toDouble(),
      expirationDate: (map['expirationDate'] as Timestamp?)?.toDate(),
      manufacturingDate: (map['manufacturingDate'] as Timestamp?)?.toDate(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'purchaseId': purchaseId,
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'cartonQuantity': cartonQuantity,
      'piecesPerCarton': piecesPerCarton,
      'pricePerCarton': pricePerCarton,
      'pricePerPiece': pricePerPiece,
      'expirationDate': expirationDate == null ? null : Timestamp.fromDate(expirationDate!),
      'manufacturingDate': manufacturingDate == null ? null : Timestamp.fromDate(manufacturingDate!),
      'totalPrice': totalPrice,
    };
  }

  PurchaseItemModel copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    String? barcode,
    int? cartonQuantity,
    int? piecesPerCarton,
    double? pricePerCarton,
    double? pricePerPiece,
    DateTime? expirationDate,
    DateTime? manufacturingDate,
    double? totalPrice,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      cartonQuantity: cartonQuantity ?? this.cartonQuantity,
      piecesPerCarton: piecesPerCarton ?? this.piecesPerCarton,
      pricePerCarton: pricePerCarton ?? this.pricePerCarton,
      pricePerPiece: pricePerPiece ?? this.pricePerPiece,
      expirationDate: expirationDate ?? this.expirationDate,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}