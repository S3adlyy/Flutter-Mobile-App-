import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

enum StockFilter { all, lowStock, outOfStock, expiringSoon, expired }

/// Holds the live product stream plus search/filter state, so every
/// screen (dashboard, list, search) reads from one consistent source
/// instead of each screen running its own Firestore query.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  List<ProductModel> _allProducts = [];
  String _searchQuery = '';
  String? _categoryFilter;
  String? _brandFilter;
  String? _supplierFilter;
  StockFilter _stockFilter = StockFilter.all;
  bool isLoading = true;

  ProductProvider() {
    _repository.watchActiveProducts().listen((products) {
      _allProducts = products;
      isLoading = false;
      notifyListeners();
    });
  }

  List<ProductModel> get allProducts => _allProducts;

  List<ProductModel> get filteredProducts {
    return _allProducts.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = p.name.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q) ||
            p.qrCode.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.supplier.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (_categoryFilter != null && p.category != _categoryFilter) return false;
      if (_brandFilter != null && p.brand != _brandFilter) return false;
      if (_supplierFilter != null && p.supplier != _supplierFilter) return false;

      switch (_stockFilter) {
        case StockFilter.lowStock:
          if (p.stockStatus != StockStatus.low && p.stockStatus != StockStatus.critical) {
            return false;
          }
          break;
        case StockFilter.outOfStock:
          if (p.stockStatus != StockStatus.outOfStock) return false;
          break;
        case StockFilter.expiringSoon:
          if (p.expirationStatus != ExpirationStatus.warning &&
              p.expirationStatus != ExpirationStatus.critical) {
            return false;
          }
          break;
        case StockFilter.expired:
          if (p.expirationStatus != ExpirationStatus.expired) return false;
          break;
        case StockFilter.all:
          break;
      }
      return true;
    }).toList();
  }

  // ---------- Dashboard aggregates ----------

  int get totalProducts => _allProducts.length;
  int get outOfStockCount =>
      _allProducts.where((p) => p.stockStatus == StockStatus.outOfStock).length;
  int get lowStockCount => _allProducts
      .where((p) => p.stockStatus == StockStatus.low || p.stockStatus == StockStatus.critical)
      .length;
  int get expiringSoonCount => _allProducts
      .where((p) =>
  p.expirationStatus == ExpirationStatus.warning ||
      p.expirationStatus == ExpirationStatus.critical)
      .length;
  int get expiredCount =>
      _allProducts.where((p) => p.expirationStatus == ExpirationStatus.expired).length;
  double get totalInventoryValue =>
      _allProducts.fold(0.0, (sum, p) => sum + p.inventoryValue);
  double get totalExpectedProfit =>
      _allProducts.fold(0.0, (sum, p) => sum + p.expectedProfit);
  Set<String> get categories => _allProducts.map((p) => p.category).toSet();
  Set<String> get suppliers => _allProducts.map((p) => p.supplier).toSet();

  // ---------- Search/filter setters ----------

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setBrandFilter(String? brand) {
    _brandFilter = brand;
    notifyListeners();
  }

  void setSupplierFilter(String? supplier) {
    _supplierFilter = supplier;
    notifyListeners();
  }

  void setStockFilter(StockFilter filter) {
    _stockFilter = filter;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _brandFilter = null;
    _supplierFilter = null;
    _stockFilter = StockFilter.all;
    notifyListeners();
  }
}