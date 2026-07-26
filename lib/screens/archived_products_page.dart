import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import '../services/storage_service.dart';
import '../widgets/status_badges.dart';

/// Admin-only. Shows everything archived via ProductListPage's "Archive"
/// action, with a way to bring them back (Restore) or remove them for
/// good (Delete Permanently). This is what makes Archive actually useful
/// instead of a one-way trip — restored products reappear in the normal
/// product list immediately since it's all one real-time stream.
class ArchivedProductsPage extends StatelessWidget {
  const ArchivedProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Products')),
      body: StreamBuilder<List<ProductModel>>(
        stream: repository.watchArchivedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final archived = snapshot.data ?? [];
          if (archived.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('No archived products'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: archived.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = archived[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text('${product.category} • Qty: ${product.stockQuantity}',
                            style: const TextStyle(fontSize: 12.5)),
                        const SizedBox(width: 8),
                        StockStatusBadge(status: product.stockStatus),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'restore') {
                        _restore(context, repository, product);
                      } else if (action == 'delete') {
                        _confirmPermanentDelete(context, repository, product);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(children: [
                          Icon(Icons.restore_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Restore to Products'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _restore(BuildContext context, ProductRepository repository, ProductModel product) async {
    await repository.restoreProduct(product.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} restored to Products')),
      );
    }
  }

  void _confirmPermanentDelete(
      BuildContext context, ProductRepository repository, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
            '${product.name} will be permanently deleted and cannot be recovered or re-added automatically.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await StorageService().deleteProductImage(product.id);
              await repository.deleteProductPermanently(product.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} deleted permanently')),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}