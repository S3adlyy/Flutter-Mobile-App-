import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

/// Handles all purchase-related database operations.
/// Also updates product stock when purchases are completed.
class PurchaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductRepository _productRepository = ProductRepository();

  CollectionReference<Map<String, dynamic>> get _purchasesRef =>
      _firestore.collection('purchases');

  CollectionReference<Map<String, dynamic>> get _purchaseItemsRef =>
      _firestore.collection('purchaseItems');

  /// Get all purchases with optional filtering
  Stream<List<PurchaseModel>> watchPurchases({
    DateTime? fromDate,
    DateTime? toDate,
    String? supplierId,
  }) {
    var query = _purchasesRef
        .orderBy('purchaseDate', descending: true)
        .limit(1000);

    if (supplierId != null && supplierId.isNotEmpty) {
      query = _purchasesRef
          .where('supplierId', isEqualTo: supplierId)
          .orderBy('purchaseDate', descending: true);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((d) => PurchaseModel.fromMap(d.data(), d.id))
          .toList();
    });
  }

  /// Get a single purchase with its items
  Future<PurchaseModel?> getPurchase(String purchaseId) async {
    final doc = await _purchasesRef.doc(purchaseId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PurchaseModel.fromMap(doc.data()!, doc.id);
  }

  /// Get all items for a specific purchase
  Future<List<PurchaseItemModel>> getPurchaseItems(String purchaseId) async {
    final snap = await _purchaseItemsRef
        .where('purchaseId', isEqualTo: purchaseId)
        .get();
    return snap.docs
        .map((d) => PurchaseItemModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Stream items for a specific purchase
  Stream<List<PurchaseItemModel>> watchPurchaseItems(String purchaseId) {
    return _purchaseItemsRef
        .where('purchaseId', isEqualTo: purchaseId)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => PurchaseItemModel.fromMap(d.data(), d.id))
        .toList());
  }

  /// Create a new purchase with items.
  Future<String> createPurchaseWithItems({
    required PurchaseModel purchase,
    required List<PurchaseItemModel> items,
    required String adminUid,
    required String adminName,
  }) async {
    final purchaseRef = _purchasesRef.doc();

    // Calculate total from items
    final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);

    final updatedPurchase = purchase.copyWith(
      id: purchaseRef.id,
      totalAmount: totalAmount,
      createdBy: adminUid,
      createdByName: adminName,
      createdAt: DateTime.now(),
      status: PurchaseStatus.completed,
    );

    // Use a batch write for atomic operation
    final batch = _firestore.batch();

    // Set the purchase document
    batch.set(purchaseRef, updatedPurchase.toMap());

    // Create all purchase items and update products
    for (final item in items) {
      final itemRef = _purchaseItemsRef.doc();
      final itemWithId = item.copyWith(
        id: itemRef.id,
        purchaseId: purchaseRef.id,
      );
      batch.set(itemRef, itemWithId.toMap());

      // Update product stock
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stockQuantity + item.totalPieces;
        final productRef = _firestore.collection('products').doc(item.productId);
        batch.update(productRef, {
          'stockQuantity': newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastModifiedBy': adminName,
          'totalPurchased': FieldValue.increment(item.totalPieces),
          'averagePurchasePrice': _calculateNewAveragePrice(
            product.averagePurchasePrice,
            product.totalPurchased,
            item.pricePerPiece,
            item.totalPieces,
          ),
        });
      }
    }

    await batch.commit();
    return purchaseRef.id;
  }

  /// Calculate new average purchase price
  double _calculateNewAveragePrice(
      double currentAverage,
      int currentTotalPurchased,
      double newPricePerPiece,
      int newQuantity,
      ) {
    if (currentTotalPurchased == 0) {
      return newPricePerPiece;
    }
    final totalCost = (currentAverage * currentTotalPurchased) + (newPricePerPiece * newQuantity);
    final totalQuantity = currentTotalPurchased + newQuantity;
    return totalCost / totalQuantity;
  }

  /// Cancel a purchase
  Future<void> cancelPurchase(String purchaseId) async {
    final purchase = await getPurchase(purchaseId);
    if (purchase == null) return;

    if (purchase.status == PurchaseStatus.cancelled) return;

    final items = await getPurchaseItems(purchaseId);
    final batch = _firestore.batch();

    batch.update(
      _purchasesRef.doc(purchaseId),
      {'status': PurchaseStatus.cancelled.name},
    );

    for (final item in items) {
      final product = await _productRepository.getProduct(item.productId);
      if (product != null) {
        final newStock = product.stockQuantity - item.totalPieces;
        final productRef = _firestore.collection('products').doc(item.productId);
        batch.update(productRef, {
          'stockQuantity': newStock < 0 ? 0 : newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastModifiedBy': 'System (Purchase Cancelled)',
          'totalPurchased': FieldValue.increment(-item.totalPieces),
        });
      }
    }

    await batch.commit();
  }

  /// Get purchase history for a specific product
  Future<List<PurchaseItemModel>> getProductPurchaseHistory(String productId) async {
    final snap = await _purchaseItemsRef
        .where('productId', isEqualTo: productId)
        .get();

    final items = snap.docs
        .map((d) => PurchaseItemModel.fromMap(d.data(), d.id))
        .toList();

    final Map<String, DateTime> purchaseDates = {};
    for (final item in items) {
      final purchase = await getPurchase(item.purchaseId);
      if (purchase != null) {
        purchaseDates[item.purchaseId] = purchase.purchaseDate;
      }
    }

    items.sort((a, b) {
      final dateA = purchaseDates[a.purchaseId] ?? DateTime(2000);
      final dateB = purchaseDates[b.purchaseId] ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return items;
  }

  /// Get total purchase value over a period
  Future<double> getTotalPurchaseValue({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _purchasesRef
        .where('status', isEqualTo: PurchaseStatus.completed.name);

    if (fromDate != null) {
      query = query.where('purchaseDate', isGreaterThanOrEqualTo: fromDate);
    }
    if (toDate != null) {
      query = query.where('purchaseDate', isLessThanOrEqualTo: toDate);
    }

    final snap = await query.get();
    double total = 0;
    for (final d in snap.docs) {
      final data = d.data();
      total += (data['totalAmount'] ?? 0).toDouble();
    }
    return total;
  }

  /// Get purchases by supplier
  Future<List<PurchaseModel>> getPurchasesBySupplier(String supplierId) async {
    final snap = await _purchasesRef
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('purchaseDate', descending: true)
        .get();
    return snap.docs
        .map((d) => PurchaseModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Get purchase statistics
  Future<Map<String, dynamic>> getPurchaseStats() async {
    final completedSnap = await _purchasesRef
        .where('status', isEqualTo: PurchaseStatus.completed.name)
        .get();

    final totalPurchases = completedSnap.docs.length;
    double totalValue = 0;
    for (final d in completedSnap.docs) {
      totalValue += (d.data()['totalAmount'] ?? 0).toDouble();
    }

    return {
      'totalPurchases': totalPurchases,
      'totalValue': totalValue,
      'averageValue': totalPurchases > 0 ? totalValue / totalPurchases : 0,
    };
  }
}