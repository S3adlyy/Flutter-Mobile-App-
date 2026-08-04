import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
import '../providers/purchase_provider.dart';
import '../theme/app_theme.dart';

/// Shows detailed information about a specific purchase,
/// including all items, pricing, and totals.
class PurchaseDetailPage extends StatefulWidget {
  final String purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  PurchaseModel? _purchase;
  List<PurchaseItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final purchaseProvider = context.read<PurchaseProvider>();
    await purchaseProvider.loadPurchaseItems(widget.purchaseId);

    // Use a loop or firstWhere with explicit type to avoid null issues
    PurchaseModel? foundPurchase;
    for (final p in purchaseProvider.purchases) {
      if (p.id == widget.purchaseId) {
        foundPurchase = p;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _purchase = foundPurchase;
        _items = purchaseProvider.currentPurchaseItems;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return Colors.orange;
      case PurchaseStatus.completed:
        return Colors.green;
      case PurchaseStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_purchase == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Details')),
        body: const Center(child: Text('Purchase not found')),
      );
    }

    final totalPieces = _items.fold(0, (sum, item) => sum + item.totalPieces);
    final statusColor = _getStatusColor(_purchase!.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase #${_purchase!.id.substring(0, 8)}'),
        actions: [
          if (_purchase!.status == PurchaseStatus.pending)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: () => _confirmCancel(),
              tooltip: 'Cancel Purchase',
            ),
        ],
      ),
      body: Column(
        children: [
          // Purchase header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _purchase!.supplierName,
                      style: AppText.display.copyWith(fontSize: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _purchase!.status.name.toUpperCase(),
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatDate(_purchase!.purchaseDate),
                      style: AppText.body.copyWith(color: AppColors.taupe),
                    ),
                    const SizedBox(width: 16),
                    if (_purchase!.invoiceNumber != null)
                      Text(
                        'Invoice: ${_purchase!.invoiceNumber}',
                        style: AppText.body.copyWith(color: AppColors.taupe),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created by: ${_purchase!.createdByName}',
                  style: AppText.body.copyWith(color: AppColors.taupe, fontSize: 12),
                ),
              ],
            ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(
                  label: 'Items',
                  value: _items.length.toString(),
                ),
                _SummaryStat(
                  label: 'Total Pieces',
                  value: totalPieces.toString(),
                ),
                _SummaryStat(
                  label: 'Total',
                  value: '\$${_purchase!.totalAmount.toStringAsFixed(2)}',
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No items in this purchase'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _PurchaseItemDetailCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Purchase?'),
        content: const Text(
            'This will reverse all stock adjustments from this purchase.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<PurchaseProvider>()
                  .cancelPurchase(widget.purchaseId);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Purchase cancelled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel purchase'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Summary stat in the header
class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SummaryStat({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.label.copyWith(
            fontSize: 18,
            color: isHighlighted ? AppColors.amber : null,
          ),
        ),
        Text(
          label,
          style: AppText.body.copyWith(
            color: AppColors.taupe,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Individual purchase item card in the detail view
class _PurchaseItemDetailCard extends StatelessWidget {
  final PurchaseItemModel item;

  const _PurchaseItemDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: AppText.label.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Barcode: ${item.barcode}',
              style: AppText.body.copyWith(color: AppColors.taupe, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DetailChip(
                  label: 'Cartons',
                  value: item.cartonQuantity.toString(),
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  label: 'Pcs/Carton',
                  value: item.piecesPerCarton.toString(),
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  label: 'Total Pcs',
                  value: item.totalPieces.toString(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${item.pricePerCarton.toStringAsFixed(2)}/carton',
                  style: AppText.body.copyWith(
                    color: AppColors.taupe,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: AppText.label.copyWith(
                    fontSize: 16,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            if (item.expirationDate != null || item.manufacturingDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (item.expirationDate != null)
                    Text(
                      'Exp: ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}',
                      style: AppText.body.copyWith(
                        color: AppColors.taupe,
                        fontSize: 11,
                      ),
                    ),
                  if (item.expirationDate != null && item.manufacturingDate != null)
                    const SizedBox(width: 12),
                  if (item.manufacturingDate != null)
                    Text(
                      'MFG: ${item.manufacturingDate!.day}/${item.manufacturingDate!.month}/${item.manufacturingDate!.year}',
                      style: AppText.body.copyWith(
                        color: AppColors.taupe,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip for detail stats
class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 10,
              color: AppColors.taupe,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppText.label.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}