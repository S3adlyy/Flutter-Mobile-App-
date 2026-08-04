import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

/// A reusable dialog for searching and selecting products.
class ProductSearchDialog extends StatefulWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductSelected;

  const ProductSearchDialog({
    super.key,
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  String _searchQuery = '';
  ProductModel? _selectedProduct;

  List<ProductModel> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.products;
    final q = _searchQuery.toLowerCase();
    return widget.products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.supplier.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Product',
                  style: AppText.display.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Search bar
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Product list
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No products available'
                      : 'No products found',
                  style: AppText.body.copyWith(color: AppColors.taupe),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final isSelected = _selectedProduct?.id == product.id;

                  return ListTile(
                    leading: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        image: product.imageUrl != null
                            ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) => null,
                        )
                            : null,
                      ),
                      child: product.imageUrl == null
                          ? Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.taupe,
                      )
                          : null,
                    ),
                    title: Text(
                      product.name,
                      style: AppText.label.copyWith(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${product.category} • ${product.brand} • Qty: ${product.stockQuantity}',
                      style: AppText.body.copyWith(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() => _selectedProduct = product);
                    },
                  );
                },
              ),
            ),

            // Action buttons
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedProduct == null
                        ? null
                        : () {
                      widget.onProductSelected(_selectedProduct!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}