import 'package:flutter/foundation.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../repositories/sale_repository.dart';
import '../repositories/product_repository.dart';

/// Centralized sale state management.
class SaleProvider extends ChangeNotifier {
  final SaleRepository _saleRepository = SaleRepository();
  final ProductRepository _productRepository = ProductRepository();

  List<SaleModel> _sales = [];
  List<SaleItemModel> _currentSaleItems = [];
  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SaleModel> get sales => _sales;
  List<SaleItemModel> get currentSaleItems => _currentSaleItems;
  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Dashboard aggregates
  double get totalSalesValue {
    return _sales
        .where((s) => s.status == SaleStatus.completed)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  int get totalSalesCount {
    return _sales
        .where((s) => s.status == SaleStatus.completed)
        .length;
  }

  double get averageSaleValue {
    if (totalSalesCount == 0) return 0;
    return totalSalesValue / totalSalesCount;
  }

  /// Initialize - start listening to sales and clients
  void init() {
    _saleRepository.watchSales().listen((sales) {
      _sales = sales;
      notifyListeners();
    });

    // Load clients immediately
    _loadClients();
  }

  /// Load clients - public method that triggers UI update
  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();

    try {
      final clients = await _saleRepository.getAllClients();
      _clients = clients;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Private method for internal use
  Future<void> _loadClients() async {
    try {
      final clients = await _saleRepository.getAllClients();
      _clients = clients;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh clients - alias for loadClients
  Future<void> refreshClients() async {
    await loadClients();
  }

  /// Refresh sales
  Future<void> refreshSales() async {
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

  /// Get items for a specific sale
  Future<void> loadSaleItems(String saleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSaleItems = await _saleRepository.getSaleItems(saleId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a new sale with items
  Future<bool> createSale({
    required String clientId,
    required String clientName,
    required String clientPhone,
    required List<SaleItemInput> items,
    required String adminUid,
    required String adminName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build sale model
      final sale = SaleModel(
        id: '',
        clientId: clientId,
        clientName: clientName,
        clientPhone: clientPhone,
        saleDate: DateTime.now(),
        total: 0,
        createdBy: adminUid,
        createdByName: adminName,
        createdAt: DateTime.now(),
        status: SaleStatus.completed,
      );

      // Build sale items
      final saleItems = items.map((input) {
        final product = input.product;
        final piecesPerCarton = input.piecesPerCarton;

        // Calculate subtotal
        final subtotal = (input.cartonsSold * input.pricePerCarton) +
            (input.piecesSold * input.pricePerPiece);

        return SaleItemModel(
          id: '',
          saleId: '',
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          piecesPerCarton: piecesPerCarton,
          cartonsSold: input.cartonsSold,
          piecesSold: input.piecesSold,
          pricePerCarton: input.pricePerCarton,
          pricePerPiece: input.pricePerPiece,
          subtotal: subtotal,
        );
      }).toList();

      // Create sale
      await _saleRepository.createSaleWithItems(
        sale: sale,
        items: saleItems,
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

  /// Cancel a sale
  Future<bool> cancelSale(String saleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _saleRepository.cancelSale(saleId);
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

  /// Create a new client - FIXED with proper UI update
  Future<String?> createClient({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? taxId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final client = ClientModel(
        id: '',
        name: name,
        phone: phone,
        email: email,
        address: address,
        taxId: taxId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      final id = await _saleRepository.createClient(client);

      // IMPORTANT: Reload clients after creating a new one
      await _loadClients();

      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Input model for creating a sale item
class SaleItemInput {
  final ProductModel product;
  final int piecesPerCarton;
  final int cartonsSold;
  final int piecesSold;
  final double pricePerCarton;
  final double pricePerPiece;

  SaleItemInput({
    required this.product,
    required this.piecesPerCarton,
    required this.cartonsSold,
    required this.piecesSold,
    required this.pricePerCarton,
    required this.pricePerPiece,
  });
}