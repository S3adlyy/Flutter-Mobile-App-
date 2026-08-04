import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale_item_model.dart';
import '../models/sale_model.dart';
import '../providers/sale_provider.dart';
import '../theme/app_theme.dart';

/// Shows detailed information about a specific sale,
/// including all items, pricing, and totals.
class SaleDetailPage extends StatefulWidget {
  final String saleId;

  const SaleDetailPage({super.key, required this.saleId});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  SaleModel? _sale;
  List<SaleItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final saleProvider = context.read<SaleProvider>();
    await saleProvider.loadSaleItems(widget.saleId);

    // Find the sale in the provider's list
    SaleModel? foundSale;
    for (final s in saleProvider.sales) {
      if (s.id == widget.saleId) {
        foundSale = s;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _sale = foundSale;
        _items = saleProvider.currentSaleItems;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.pending:
        return Colors.orange;
      case SaleStatus.completed:
        return Colors.green;
      case SaleStatus.cancelled:
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

    if (_sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sale Details')),
        body: const Center(child: Text('Sale not found')),
      );
    }

    final totalPieces = _items.fold(0, (sum, item) => sum + item.totalPiecesSold);
    final statusColor = _getStatusColor(_sale!.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sale #${_sale!.id.substring(0, 8)}'),
        actions: [
          if (_sale!.status == SaleStatus.completed)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: () => _confirmCancel(),
              tooltip: 'Cancel Sale',
            ),
        ],
      ),
      body: Column(
        children: [
          // Sale header
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
                    Expanded(
                      child: Text(
                        _sale!.clientName,
                        style: AppText.display.copyWith(fontSize: 20),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _sale!.status.name.toUpperCase(),
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
                    Icon(Icons.phone_outlined, size: 16, color: AppColors.taupe),
                    const SizedBox(width: 4),
                    Text(
                      _sale!.clientPhone,
                      style: AppText.body.copyWith(color: AppColors.taupe),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.taupe),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(_sale!.saleDate),
                      style: AppText.body.copyWith(color: AppColors.taupe),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created by: ${_sale!.createdByName}',
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
                  value: '\$${_sale!.total.toStringAsFixed(2)}',
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No items in this sale'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _SaleItemDetailCard(item: item);
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
        title: const Text('Cancel Sale?'),
        content: const Text(
            'This will reverse all stock adjustments from this sale.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<SaleProvider>()
                  .cancelSale(widget.saleId);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sale cancelled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel sale'),
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

/// Individual sale item card in the detail view
class _SaleItemDetailCard extends StatelessWidget {
  final SaleItemModel item;

  const _SaleItemDetailCard({required this.item});

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
                  value: item.cartonsSold.toString(),
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  label: 'Pieces',
                  value: item.piecesSold.toString(),
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  label: 'Total Pcs',
                  value: item.totalPiecesSold.toString(),
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
                  '\$${item.pricePerPiece.toStringAsFixed(2)}/piece',
                  style: AppText.body.copyWith(
                    color: AppColors.taupe,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: AppText.label.copyWith(
                    fontSize: 16,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${item.cartonsSold} carton${item.cartonsSold > 1 ? 's' : ''} × ${item.piecesPerCarton} pcs/carton + ${item.piecesSold} pcs = ${item.totalPiecesSold} pcs',
                style: AppText.body.copyWith(
                  fontSize: 11,
                  color: AppColors.amber,
                ),
              ),
            ),
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