import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

/// Handles all sale-related database operations.
class SaleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductRepository _productRepository = ProductRepository();

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _firestore.collection('sales');

  CollectionReference<Map<String, dynamic>> get _saleItemsRef =>
      _firestore.collection('saleItems');

  CollectionReference<Map<String, dynamic>> get _clientsRef =>
      _firestore.collection('clients');

  /// Get all sales with optional filtering
  Stream<List<SaleModel>> watchSales({
    DateTime? fromDate,
    DateTime? toDate,
    String? clientId,
  }) {
    var query = _salesRef
        .where('status', isEqualTo: SaleStatus.completed.name)
        .orderBy('saleDate', descending: true)
        .limit(1000);

    if (clientId != null && clientId.isNotEmpty) {
      query = _salesRef
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: SaleStatus.completed.name)
          .orderBy('saleDate', descending: true);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => SaleModel.fromMap(d.data(), d.id))
          .toList();
    });
  }

  /// Get a single sale
  Future<SaleModel?> getSale(String saleId) async {
    final doc = await _salesRef.doc(saleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SaleModel.fromMap(doc.data()!, doc.id);
  }

  /// Get all items for a specific sale
  Future<List<SaleItemModel>> getSaleItems(String saleId) async {
    final snap = await _saleItemsRef
        .where('saleId', isEqualTo: saleId)
        .get();
    return snap.docs
        .map((d) => SaleItemModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Stream items for a specific sale
  Stream<List<SaleItemModel>> watchSaleItems(String saleId) {
    return _saleItemsRef
        .where('saleId', isEqualTo: saleId)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => SaleItemModel.fromMap(d.data(), d.id))
        .toList());
  }

  /// Create a new sale with items.
  Future<String> createSaleWithItems({
    required SaleModel sale,
    required List<SaleItemModel> items,
    required String adminUid,
    required String adminName,
  }) async {
    final saleRef = _salesRef.doc();

    // Calculate total from items
    double total = 0;
    for (final item in items) {
      total += item.subtotal;
    }

    final updatedSale = sale.copyWith(
      id: saleRef.id,
      total: total,
      createdBy: adminUid,
      createdByName: adminName,
      createdAt: DateTime.now(),
      status: SaleStatus.completed,
    );

    final batch = _firestore.batch();

    // Set the sale document
    batch.set(saleRef, updatedSale.toMap());

    // Create all sale items and update products
    for (final item in items) {
      final itemRef = _saleItemsRef.doc();
      final itemWithId = item.copyWith(
        id: itemRef.id,
        saleId: saleRef.id,
      );
      batch.set(itemRef, itemWithId.toMap());

      // Update product stock (deduct cartons and pieces)
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        // Convert cartons to pieces
        final piecesFromCartons = item.cartonsSold * item.piecesPerCarton;
        final totalPiecesDeducted = piecesFromCartons + item.piecesSold;

        // Calculate new stock
        final newStock = product.stockQuantity - totalPiecesDeducted;

        final productRef = _firestore.collection('products').doc(item.productId);
        batch.update(productRef, {
          'stockQuantity': newStock < 0 ? 0 : newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastModifiedBy': adminName,
        });
      }
    }

    // Update client's total purchased and last purchase date
    final clientRef = _clientsRef.doc(sale.clientId);
    batch.update(clientRef, {
      'totalPurchased': FieldValue.increment(total),
      'purchaseCount': FieldValue.increment(1),
      'lastPurchaseDate': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return saleRef.id;
  }

  /// Cancel a sale (reverse stock)
  Future<void> cancelSale(String saleId) async {
    final sale = await getSale(saleId);
    if (sale == null) return;

    if (sale.status == SaleStatus.cancelled) return;

    final items = await getSaleItems(saleId);
    final batch = _firestore.batch();

    batch.update(
      _salesRef.doc(saleId),
      {'status': SaleStatus.cancelled.name},
    );

    // Reverse stock adjustments
    for (final item in items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final piecesFromCartons = item.cartonsSold * item.piecesPerCarton;
        final totalPiecesAdded = piecesFromCartons + item.piecesSold;
        final newStock = product.stockQuantity + totalPiecesAdded;

        final productRef = _firestore.collection('products').doc(item.productId);
        batch.update(productRef, {
          'stockQuantity': newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastModifiedBy': 'System (Sale Cancelled)',
        });
      }
    }

    // Update client's total purchased
    final clientRef = _clientsRef.doc(sale.clientId);
    batch.update(clientRef, {
      'totalPurchased': FieldValue.increment(-sale.total),
      'purchaseCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Get all clients
  Future<List<ClientModel>> getAllClients() async {
    try {
      final snap = await _clientsRef.get();
      final clients = snap.docs
          .map((d) => ClientModel.fromMap(d.data(), d.id))
          .toList();
      final activeClients = clients.where((c) => c.isActive == true).toList();
      activeClients.sort((a, b) => a.name.compareTo(b.name));
      return activeClients;
    } catch (e) {
      print('Error getting clients: $e');
      return [];
    }
  }

  /// Get a client by ID
  Future<ClientModel?> getClient(String clientId) async {
    final doc = await _clientsRef.doc(clientId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ClientModel.fromMap(doc.data()!, doc.id);
  }

  /// Create a new client
  Future<String> createClient(ClientModel client) async {
    final doc = await _clientsRef.add(client.toMap());
    return doc.id;
  }

  /// Update a client - FIXED
  Future<void> updateClient(String id, ClientModel client) async {
    await _clientsRef.doc(id).update({
      'name': client.name,
      'phone': client.phone,
      'email': client.email,
      'address': client.address,
      'taxId': client.taxId,
    });
  }

  /// Delete a client (soft delete - set isActive to false) - FIXED
  Future<void> deleteClient(String id) async {
    await _clientsRef.doc(id).update({
      'isActive': false,
    });
  }

  /// Permanently delete a client - FIXED
  Future<void> permanentlyDeleteClient(String id) async {
    await _clientsRef.doc(id).delete();
  }

  /// Get total sales value over a period
  Future<double> getTotalSalesValue({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _salesRef
        .where('status', isEqualTo: SaleStatus.completed.name);

    if (fromDate != null) {
      query = query.where('saleDate', isGreaterThanOrEqualTo: fromDate);
    }
    if (toDate != null) {
      query = query.where('saleDate', isLessThanOrEqualTo: toDate);
    }

    final snap = await query.get();
    double total = 0;
    for (final d in snap.docs) {
      final data = d.data();
      total += (data['total'] ?? 0).toDouble();
    }
    return total;
  }

  /// Get sales statistics
  Future<Map<String, dynamic>> getSalesStats() async {
    final completedSnap = await _salesRef
        .where('status', isEqualTo: SaleStatus.completed.name)
        .get();

    final totalSales = completedSnap.docs.length;
    double totalValue = 0;
    for (final d in completedSnap.docs) {
      totalValue += (d.data()['total'] ?? 0).toDouble();
    }

    return {
      'totalSales': totalSales,
      'totalValue': totalValue,
      'averageValue': totalSales > 0 ? totalValue / totalSales : 0,
    };
  }
}