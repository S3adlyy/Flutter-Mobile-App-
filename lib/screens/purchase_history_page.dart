import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase_model.dart';
import '../providers/purchase_provider.dart';
import '../theme/app_theme.dart';
import 'purchase_detail_page.dart';

/// Admin-only screen showing all purchase history.
class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<PurchaseProvider>().init();
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

  List<PurchaseModel> _filteredPurchases(List<PurchaseModel> all) {
    var result = all;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
      p.supplierName.toLowerCase().contains(q) ||
          (p.invoiceNumber?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    if (_statusFilter != null) {
      result = result.where((p) => p.status.name == _statusFilter).toList();
    }

    return result;
  }

  void _confirmCancel(String purchaseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Purchase?'),
        content: const Text(
            'This will reverse all stock adjustments from this purchase. '
                'This action cannot be undone if the purchase was already completed.'
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
                  .cancelPurchase(purchaseId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'Purchase cancelled' : 'Failed to cancel purchase'
                    ),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final purchases = _filteredPurchases(purchaseProvider.purchases);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => purchaseProvider.refreshPurchases(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search supplier...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    const DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    const DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v),
                ),
              ],
            ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SummaryChip(
                  label: 'Total Purchases',
                  value: purchaseProvider.totalPurchaseCount.toString(),
                  color: AppColors.amber,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  label: 'Total Value',
                  value: '\$${purchaseProvider.totalPurchaseValue.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ],
            ),
          ),

          // Purchase list
          Expanded(
            child: purchaseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : purchases.isEmpty
                ? const Center(child: Text('No purchases found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return _PurchaseCard(
                  purchase: purchase,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PurchaseDetailPage(purchaseId: purchase.id),
                    ),
                  ),
                  onCancel: purchase.status == PurchaseStatus.pending
                      ? () => _confirmCancel(purchase.id)
                      : null,
                  getStatusColor: _getStatusColor,
                  formatDate: _formatDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary chip for the header
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.body.copyWith(fontSize: 12, color: AppColors.taupe),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppText.label.copyWith(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

/// Purchase card in the history list
class _PurchaseCard extends StatelessWidget {
  final PurchaseModel purchase;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final Color Function(PurchaseStatus) getStatusColor;
  final String Function(DateTime) formatDate;

  const _PurchaseCard({
    required this.purchase,
    required this.onTap,
    required this.getStatusColor,
    required this.formatDate,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(purchase.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      purchase.supplierName,
                      style: AppText.label.copyWith(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      purchase.status.name.toUpperCase(),
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    formatDate(purchase.purchaseDate),
                    style: AppText.body.copyWith(
                      color: AppColors.taupe,
                      fontSize: 12,
                    ),
                  ),
                  if (purchase.invoiceNumber != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Invoice: ${purchase.invoiceNumber}',
                      style: AppText.body.copyWith(
                        color: AppColors.taupe,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By: ${purchase.createdByName}',
                    style: AppText.body.copyWith(
                      color: AppColors.taupe,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${purchase.totalAmount.toStringAsFixed(2)}',
                    style: AppText.display.copyWith(
                      fontSize: 18,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Cancel Purchase'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}