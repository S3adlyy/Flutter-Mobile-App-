import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'status_badges.dart';

enum ProductCardAction { edit, archive, deletePermanently }

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDeletePermanently;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onEdit,
    this.onArchive,
    this.onDeletePermanently,
  });

  bool get _hasActions => onEdit != null || onArchive != null || onDeletePermanently != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 64,
                  width: 64,
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon(scheme))
                      : _placeholderIcon(scheme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${product.category} • ${product.brand}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StockStatusBadge(status: product.stockStatus),
                        if (product.expirationStatus != ExpirationStatus.none)
                          ExpirationStatusBadge(
                            status: product.expirationStatus,
                            daysRemaining: product.daysUntilExpiration,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${product.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Qty: ${product.stockQuantity}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (_hasActions) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: PopupMenuButton<ProductCardAction>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert_rounded, size: 20, color: scheme.onSurfaceVariant),
                        onSelected: (action) {
                          switch (action) {
                            case ProductCardAction.edit:
                              onEdit?.call();
                              break;
                            case ProductCardAction.archive:
                              onArchive?.call();
                              break;
                            case ProductCardAction.deletePermanently:
                              onDeletePermanently?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: ProductCardAction.edit,
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ]),
                            ),
                          if (onArchive != null)
                            const PopupMenuItem(
                              value: ProductCardAction.archive,
                              child: Row(children: [
                                Icon(Icons.archive_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Archive'),
                              ]),
                            ),
                          if (onDeletePermanently != null)
                            const PopupMenuItem(
                              value: ProductCardAction.deletePermanently,
                              child: Row(children: [
                                Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.inventory_2_outlined, color: scheme.onSurfaceVariant),
    );
  }
}