import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Real-time stream of all non-archived products.
  Stream<List<ProductModel>> watchActiveProducts() {
    return _productsRef
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .toList());
  }

  Stream<List<ProductModel>> watchArchivedProducts() {
    return _productsRef
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final snap = await _productsRef
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ProductModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<String> addProduct(ProductModel product) async {
    final doc = await _productsRef.add(product.toMap());
    return doc.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> changes) async {
    changes['lastUpdated'] = FieldValue.serverTimestamp();
    await _productsRef.doc(id).update(changes);
  }

  /// Soft delete — keeps the record but hides it from normal views.
  Future<void> archiveProduct(String id) async {
    await _productsRef.doc(id).update({'isArchived': true});
  }

  Future<void> restoreProduct(String id) async {
    await _productsRef.doc(id).update({'isArchived': false});
  }

  /// Hard delete — only for genuinely removing bad data.
  Future<void> deleteProductPermanently(String id) async {
    await _productsRef.doc(id).delete();
  }

  Future<void> adjustStock({
    required String id,
    required int delta,
    required String modifiedBy,
  }) async {
    await _productsRef.doc(id).update({
      'stockQuantity': FieldValue.increment(delta),
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastModifiedBy': modifiedBy,
    });
  }

  // NEW METHODS for purchase management

  /// Get products by supplier
  Future<List<ProductModel>> getProductsBySupplier(String supplierId) async {
    final snap = await _productsRef
        .where('supplier', isEqualTo: supplierId)
        .where('isArchived', isEqualTo: false)
        .get();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Update product with purchase data
  Future<void> updateProductPurchaseData(String productId, {
    required int quantityAdded,
    required double pricePerPiece,
  }) async {
    final product = await getProduct(productId);
    if (product == null) return;

    final newTotalPurchased = product.totalPurchased + quantityAdded;
    final newAveragePrice = product.totalPurchased > 0
        ? ((product.averagePurchasePrice * product.totalPurchased) + (pricePerPiece * quantityAdded)) / newTotalPurchased
        : pricePerPiece;

    await _productsRef.doc(productId).update({
      'totalPurchased': newTotalPurchased,
      'averagePurchasePrice': newAveragePrice,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Get all products with low stock
  Future<List<ProductModel>> getLowStockProducts() async {
    final snap = await _productsRef
        .where('isArchived', isEqualTo: false)
        .get();

    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .where((p) => p.stockStatus == StockStatus.low || p.stockStatus == StockStatus.critical)
        .toList();
  }

  /// Get products expiring soon
  Future<List<ProductModel>> getExpiringSoonProducts() async {
    final snap = await _productsRef
        .where('isArchived', isEqualTo: false)
        .get();

    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .where((p) => p.expirationStatus == ExpirationStatus.warning ||
        p.expirationStatus == ExpirationStatus.critical)
        .toList();
  }
}