import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a purchase order from a supplier.
class PurchaseModel {
  final String id;
  final String supplierId;
  final String supplierName;
  final DateTime purchaseDate;
  final String? invoiceNumber;
  final double totalAmount;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final PurchaseStatus status;

  const PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.purchaseDate,
    this.invoiceNumber,
    required this.totalAmount,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.status = PurchaseStatus.pending,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseModel(
      id: id,
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invoiceNumber: map['invoiceNumber'],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: PurchaseStatusExtension.fromString(map['status'] ?? 'pending'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'invoiceNumber': invoiceNumber,
      'totalAmount': totalAmount,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    String? invoiceNumber,
    double? totalAmount,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    PurchaseStatus? status,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

enum PurchaseStatus {
  pending,
  completed,
  cancelled,
}

class PurchaseStatusExtension {
  static PurchaseStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PurchaseStatus.pending;
      case 'completed':
        return PurchaseStatus.completed;
      case 'cancelled':
        return PurchaseStatus.cancelled;
      default:
        return PurchaseStatus.pending;
    }
  }

  static String toStringValue(PurchaseStatus status) {
    return status.name;
  }
}