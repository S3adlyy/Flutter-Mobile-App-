import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a client/customer who makes purchases.
class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? taxId;
  final double totalPurchased;
  final int purchaseCount;
  final DateTime createdAt;
  final DateTime? lastPurchaseDate;
  final bool isActive;

  const ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.taxId,
    this.totalPurchased = 0,
    this.purchaseCount = 0,
    required this.createdAt,
    this.lastPurchaseDate,
    this.isActive = true,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      taxId: map['taxId'],
      totalPurchased: (map['totalPurchased'] ?? 0).toDouble(),
      purchaseCount: (map['purchaseCount'] ?? 0) as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPurchaseDate: (map['lastPurchaseDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'taxId': taxId,
      'totalPurchased': totalPurchased,
      'purchaseCount': purchaseCount,
      'createdAt': FieldValue.serverTimestamp(),
      'lastPurchaseDate': lastPurchaseDate == null ? null : Timestamp.fromDate(lastPurchaseDate!),
      'isActive': isActive,
    };
  }

  ClientModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    double? totalPurchased,
    int? purchaseCount,
    DateTime? lastPurchaseDate,
    bool? isActive,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      createdAt: createdAt,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      isActive: isActive ?? this.isActive,
    );
  }
}