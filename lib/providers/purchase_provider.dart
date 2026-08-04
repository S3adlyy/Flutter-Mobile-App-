import 'package:flutter/foundation.dart';
import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
// Use 'product_models' as prefix to avoid conflicts with local variables
import '../models/product_model.dart' as product_models;
import '../repositories/purchase_repository.dart';
import '../repositories/product_repository.dart';

/// Centralized purchase state management.
/// Handles purchase creation, history, and real-time updates.
class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final ProductRepository _productRepository = ProductRepository();

  List<PurchaseModel> _purchases = [];
  List<PurchaseItemModel> _currentPurchaseItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<PurchaseModel> get purchases => _purchases;
  List<PurchaseItemModel> get currentPurchaseItems => _currentPurchaseItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Dashboard aggregates
  double get totalPurchaseValue {
    return _purchases
        .where((p) => p.status == PurchaseStatus.completed)
        .fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  int get totalPurchaseCount {
    return _purchases
        .where((p) => p.status == PurchaseStatus.completed)
        .length;
  }

  double get averagePurchaseValue {
    if (totalPurchaseCount == 0) return 0;
    return totalPurchaseValue / totalPurchaseCount;
  }

  /// Initialize - start listening to purchases
  void init() {
    _purchaseRepository.watchPurchases().listen((purchases) {
      _purchases = purchases;
      notifyListeners();
    });
  }

  /// Get all purchases (refresh)
  Future<void> refreshPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get items for a specific purchase
  Future<void> loadPurchaseItems(String purchaseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentPurchaseItems = await _purchaseRepository.getPurchaseItems(purchaseId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a new purchase with items
  Future<bool> createPurchase({
    required String supplierId,
    required String supplierName,
    required String invoiceNumber,
    required List<PurchaseItemInput> items,
    required String adminUid,
    required String adminName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build purchase model
      final purchase = PurchaseModel(
        id: '',
        supplierId: supplierId,
        supplierName: supplierName,
        purchaseDate: DateTime.now(),
        invoiceNumber: invoiceNumber.isNotEmpty ? invoiceNumber : null,
        totalAmount: 0,
        createdBy: adminUid,
        createdByName: adminName,
        createdAt: DateTime.now(),
        status: PurchaseStatus.pending,
      );

      // Build purchase items
      final purchaseItems = items.map((input) {
        // Rename local variable from 'product' to 'productModel' to avoid shadowing
        final productModel = input.product;
        final pricePerPiece = input.pricePerCarton / input.piecesPerCarton;

        return PurchaseItemModel(
          id: '',
          purchaseId: '',
          productId: productModel.id,
          productName: productModel.name,
          barcode: productModel.barcode,
          cartonQuantity: input.cartonQuantity,
          piecesPerCarton: input.piecesPerCarton,
          pricePerCarton: input.pricePerCarton,
          pricePerPiece: pricePerPiece,
          expirationDate: input.expirationDate,
          manufacturingDate: input.manufacturingDate,
          totalPrice: input.cartonQuantity * input.pricePerCarton,
        );
      }).toList();

      // Create purchase
      await _purchaseRepository.createPurchaseWithItems(
        purchase: purchase,
        items: purchaseItems,
        adminUid: adminUid,
        adminName: adminName,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel a purchase
  Future<bool> cancelPurchase(String purchaseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _purchaseRepository.cancelPurchase(purchaseId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get purchase history for a product
  Future<List<PurchaseItemModel>> getProductPurchaseHistory(String productId) {
    return _purchaseRepository.getProductPurchaseHistory(productId);
  }

  /// Get available products for purchase (non-archived)
  Future<List<product_models.ProductModel>> getAvailableProducts() async {
    final snap = await _productRepository.watchActiveProducts().first;
    return snap;
  }

  /// Get purchase statistics
  Future<Map<String, dynamic>> getPurchaseStats() async {
    return await _purchaseRepository.getPurchaseStats();
  }

  /// Get purchases by supplier
  Future<List<PurchaseModel>> getPurchasesBySupplier(String supplierId) async {
    return await _purchaseRepository.getPurchasesBySupplier(supplierId);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Input model for creating a purchase item
class PurchaseItemInput {
  final product_models.ProductModel product;
  final int cartonQuantity;
  final int piecesPerCarton;
  final double pricePerCarton;
  final DateTime? expirationDate;
  final DateTime? manufacturingDate;

  PurchaseItemInput({
    required this.product,
    required this.cartonQuantity,
    required this.piecesPerCarton,
    required this.pricePerCarton,
    this.expirationDate,
    this.manufacturingDate,
  });
}