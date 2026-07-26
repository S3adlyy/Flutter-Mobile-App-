import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Real-time stream of all non-archived products. This is what powers
  /// the dashboard, the product list, and search — one stream, filtered
  /// client-side for the small catalog sizes this app targets. If your
  /// catalog grows past a few thousand SKUs, move the heavier aggregates
  /// (totals, sums) to a Cloud Function that maintains a summary doc
  /// instead of recomputing from the full stream on every client.
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

  /// Soft delete — keeps the record (and its history) but hides it from
  /// normal views. Matches the spec's "Archive" + "Restore" requirement.
  Future<void> archiveProduct(String id) async {
    await _productsRef.doc(id).update({'isArchived': true});
  }

  Future<void> restoreProduct(String id) async {
    await _productsRef.doc(id).update({'isArchived': false});
  }

  /// Hard delete — only for genuinely removing bad data. Prefer archive
  /// for normal "remove this product" actions.
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
}