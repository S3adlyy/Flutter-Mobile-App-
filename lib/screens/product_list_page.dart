import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../repositories/product_repository.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import 'add_edit_product_page.dart';
import 'archived_products_page.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archived Products',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchivedProductsPage()),
              ),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditProductPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: products.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search by name, barcode, category...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: products.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.filteredProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : RefreshIndicator(
              onRefresh: () async {
                // Stream is already real-time; this just gives
                // users the familiar pull-to-refresh affordance.
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 90),
                itemCount: products.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = products.filteredProducts[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      // Phase 2 will link this to the full
                      // Product Details page.
                    },
                    onEdit: isAdmin
                        ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditProductPage(
                            existingProduct: product),
                      ),
                    )
                        : null,
                    onArchive: isAdmin
                        ? () => _confirmArchive(context, product.id, product.name)
                        : null,
                    onDeletePermanently: isAdmin
                        ? () => _confirmPermanentDelete(context, product.id, product.name)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive product?'),
        content: Text(
            '$name will be hidden from the active catalog. You can restore it later from Archived Products.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ProductRepository().archiveProduct(id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name archived')),
                );
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          '$name and all of its data will be permanently deleted. This cannot be undone.\n\n'
              'If you just want to remove it from view but might need it again, use Archive instead.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await StorageService().deleteProductImage(id);
                await ProductRepository().deleteProductPermanently(id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name deleted permanently')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}