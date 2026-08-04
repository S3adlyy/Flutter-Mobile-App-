import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale_model.dart';
import '../providers/sale_provider.dart';
import '../theme/app_theme.dart';
import 'sale_detail_page.dart';

/// Admin-only screen showing all sales history.
class SaleHistoryPage extends StatefulWidget {
  const SaleHistoryPage({super.key});

  @override
  State<SaleHistoryPage> createState() => _SaleHistoryPageState();
}

class _SaleHistoryPageState extends State<SaleHistoryPage> {
  String _searchQuery = '';
  String? _statusFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    context.read<SaleProvider>().init();
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

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<SaleModel> _filteredSales(List<SaleModel> all) {
    var result = all;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) =>
      s.clientName.toLowerCase().contains(q) ||
          s.clientPhone.contains(q)
      ).toList();
    }

    if (_statusFilter != null) {
      result = result.where((s) => s.status.name == _statusFilter).toList();
    }

    if (_dateRange != null) {
      result = result.where((s) =>
      s.saleDate.isAfter(_dateRange!.start) &&
          s.saleDate.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    return result;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    final sales = _filteredSales(saleProvider.sales);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date range',
          ),
          if (_searchQuery.isNotEmpty || _statusFilter != null || _dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear all filters',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => saleProvider.refreshSales(),
            tooltip: 'Refresh',
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
                      hintText: 'Search client name or phone...',
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

          // Date range indicator
          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDateShort(_dateRange!.start)} - ${_formatDateShort(_dateRange!.end)}',
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _dateRange = null),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Clear'),
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
                  label: 'Total Sales',
                  value: saleProvider.totalSalesCount.toString(),
                  color: AppColors.amber,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  label: 'Total Value',
                  value: '\$${saleProvider.totalSalesValue.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  label: 'Average',
                  value: '\$${saleProvider.averageSaleValue.toStringAsFixed(2)}',
                  color: AppColors.taupe,
                ),
              ],
            ),
          ),

          // Sales list
          Expanded(
            child: saleProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sales.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sell_outlined,
                    size: 48,
                    color: AppColors.taupe,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty || _statusFilter != null || _dateRange != null
                        ? 'No sales match your filters'
                        : 'No sales recorded yet',
                    style: AppText.body.copyWith(color: AppColors.taupe),
                  ),
                  if (_searchQuery.isNotEmpty || _statusFilter != null || _dateRange != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return _SaleCard(
                  sale: sale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaleDetailPage(saleId: sale.id),
                    ),
                  ),
                  onCancel: sale.status == SaleStatus.completed
                      ? () => _confirmCancel(sale.id)
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

  void _confirmCancel(String saleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Sale?'),
        content: const Text(
            'This will reverse all stock adjustments from this sale. '
                'This action cannot be undone if the sale was already completed.'
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
                  .cancelSale(saleId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'Sale cancelled' : 'Failed to cancel sale'
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

/// Sale card in the history list
class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final Color Function(SaleStatus) getStatusColor;
  final String Function(DateTime) formatDate;

  const _SaleCard({
    required this.sale,
    required this.onTap,
    required this.getStatusColor,
    required this.formatDate,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(sale.status);

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
                      sale.clientName,
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
                      sale.status.name.toUpperCase(),
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
                  Icon(Icons.phone_outlined, size: 14, color: AppColors.taupe),
                  const SizedBox(width: 4),
                  Text(
                    sale.clientPhone,
                    style: AppText.body.copyWith(
                      color: AppColors.taupe,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.taupe),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(sale.saleDate),
                    style: AppText.body.copyWith(
                      color: AppColors.taupe,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By: ${sale.createdByName}',
                    style: AppText.body.copyWith(
                      color: AppColors.taupe,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${sale.total.toStringAsFixed(2)}',
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
                    child: const Text('Cancel Sale'),
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