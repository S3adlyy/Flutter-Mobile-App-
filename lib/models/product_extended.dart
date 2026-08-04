/// Extension methods for ProductModel to support carton-based sales.
/// This extends the existing ProductModel without modifying it.
import '../models/product_model.dart';

extension ProductModelSalesExtension on ProductModel {
  /// Calculate stock in cartons (floor division)
  int get stockCartons => stockQuantity ~/ 30; // Default 30 pieces per carton

  /// Calculate remaining pieces after cartons
  int get stockPieces => stockQuantity % 30;

  /// Price per carton (default: pricePerPiece * piecesPerCarton)
  double get sellingPricePerCarton => sellingPrice * 30;

  /// Price per piece (already exists as sellingPrice)
  double get sellingPricePerPiece => sellingPrice;

  /// Number of pieces per carton (default: 30, but should be stored per product)
  int get piecesPerCarton => 30; // This should be stored in the product model

  /// Validate if a sale quantity is available
  bool canSellCartons(int cartons) => stockCartons >= cartons;
  bool canSellPieces(int pieces) => stockPieces >= pieces;
  bool canSell(int cartons, int pieces) {
    final totalPieces = (cartons * piecesPerCarton) + pieces;
    return stockQuantity >= totalPieces;
  }
}