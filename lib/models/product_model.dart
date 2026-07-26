import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus { healthy, low, critical, outOfStock }
enum ExpirationStatus { good, warning, critical, expired, none }

class ProductModel {
  final String id;
  final String barcode;
  final String qrCode;
  final String name;
  final String category;
  final String brand;
  final String description;
  final String supplier;
  final double purchasePrice;
  final double sellingPrice;
  final int stockQuantity;
  final int reservedQuantity;
  final int minimumStock;
  final int maximumStock;
  final DateTime? expirationDate;
  final DateTime? manufacturingDate;
  final String? imageUrl;
  final DateTime lastUpdated;
  final String createdBy;
  final String lastModifiedBy;
  final bool isArchived;

  const ProductModel({
    required this.id,
    required this.barcode,
    required this.qrCode,
    required this.name,
    required this.category,
    required this.brand,
    required this.description,
    required this.supplier,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.reservedQuantity,
    required this.minimumStock,
    required this.maximumStock,
    this.expirationDate,
    this.manufacturingDate,
    this.imageUrl,
    required this.lastUpdated,
    required this.createdBy,
    required this.lastModifiedBy,
    this.isArchived = false,
  });

  // ---------- Computed / derived fields ----------

  int get availableQuantity => stockQuantity - reservedQuantity;

  double get profitMargin =>
      purchasePrice <= 0 ? 0 : ((sellingPrice - purchasePrice) / purchasePrice) * 100;

  double get profitPerUnit => sellingPrice - purchasePrice;

  double get inventoryValue => purchasePrice * stockQuantity;

  double get expectedProfit => profitPerUnit * stockQuantity;

  double get stockPercentage {
    if (maximumStock <= 0) return 0;
    return (stockQuantity / maximumStock).clamp(0, 1).toDouble();
  }

  int get remainingCapacity => (maximumStock - stockQuantity).clamp(0, maximumStock);

  StockStatus get stockStatus {
    if (stockQuantity <= 0) return StockStatus.outOfStock;
    if (stockQuantity <= minimumStock * 0.5) return StockStatus.critical;
    if (stockQuantity <= minimumStock) return StockStatus.low;
    return StockStatus.healthy;
  }

  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  ExpirationStatus get expirationStatus {
    final days = daysUntilExpiration;
    if (days == null) return ExpirationStatus.none;
    if (days < 0) return ExpirationStatus.expired;
    if (days <= 7) return ExpirationStatus.critical;
    if (days <= 30) return ExpirationStatus.warning;
    return ExpirationStatus.good;
  }

  // ---------- Firestore mapping ----------

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? toDate(dynamic v) => v == null ? null : (v as Timestamp).toDate();
    return ProductModel(
      id: id,
      barcode: map['barcode'] ?? '',
      qrCode: map['qrCode'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      description: map['description'] ?? '',
      supplier: map['supplier'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      stockQuantity: (map['stockQuantity'] ?? 0) as int,
      reservedQuantity: (map['reservedQuantity'] ?? 0) as int,
      minimumStock: (map['minimumStock'] ?? 0) as int,
      maximumStock: (map['maximumStock'] ?? 0) as int,
      expirationDate: toDate(map['expirationDate']),
      manufacturingDate: toDate(map['manufacturingDate']),
      imageUrl: map['imageUrl'],
      lastUpdated: toDate(map['lastUpdated']) ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      lastModifiedBy: map['lastModifiedBy'] ?? '',
      isArchived: map['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'qrCode': qrCode,
      'name': name,
      'category': category,
      'brand': brand,
      'description': description,
      'supplier': supplier,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'reservedQuantity': reservedQuantity,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'expirationDate': expirationDate == null ? null : Timestamp.fromDate(expirationDate!),
      'manufacturingDate': manufacturingDate == null ? null : Timestamp.fromDate(manufacturingDate!),
      'imageUrl': imageUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'isArchived': isArchived,
    };
  }

  ProductModel copyWith({
    String? name,
    String? category,
    String? brand,
    String? description,
    String? supplier,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? reservedQuantity,
    int? minimumStock,
    int? maximumStock,
    DateTime? expirationDate,
    DateTime? manufacturingDate,
    String? imageUrl,
    String? lastModifiedBy,
    bool? isArchived,
  }) {
    return ProductModel(
      id: id,
      barcode: barcode,
      qrCode: qrCode,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      supplier: supplier ?? this.supplier,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      expirationDate: expirationDate ?? this.expirationDate,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: DateTime.now(),
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}