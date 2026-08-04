import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a sale/order made to a client.
class SaleModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final DateTime saleDate;
  final double total;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final SaleStatus status;

  const SaleModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.saleDate,
    required this.total,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.status = SaleStatus.completed,
  });

  factory SaleModel.fromMap(Map<String, dynamic> map, String id) {
    return SaleModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      saleDate: (map['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (map['total'] ?? 0).toDouble(),
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SaleStatusExtension.fromString(map['status'] ?? 'completed'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'saleDate': Timestamp.fromDate(saleDate),
      'total': total,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
    };
  }

  SaleModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    DateTime? saleDate,
    double? total,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    SaleStatus? status,
  }) {
    return SaleModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      saleDate: saleDate ?? this.saleDate,
      total: total ?? this.total,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

enum SaleStatus {
  pending,
  completed,
  cancelled,
}

class SaleStatusExtension {
  static SaleStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SaleStatus.pending;
      case 'completed':
        return SaleStatus.completed;
      case 'cancelled':
        return SaleStatus.cancelled;
      default:
        return SaleStatus.completed;
    }
  }

  static String toStringValue(SaleStatus status) {
    return status.name;
  }
}