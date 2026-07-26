import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'product_list_page.dart';

class InventoryDashboardPage extends StatelessWidget {
  const InventoryDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (products.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stats = <_StatCardData>[
      _StatCardData('Total Products', products.totalProducts.toDouble(),
          Icons.inventory_2_outlined, scheme.primary),
      _StatCardData('Categories', products.categories.length.toDouble(),
          Icons.category_outlined, const Color(0xFF6C63FF)),
      _StatCardData('Suppliers', products.suppliers.length.toDouble(),
          Icons.local_shipping_outlined, const Color(0xFF00A896)),
      _StatCardData('Out of Stock', products.outOfStockCount.toDouble(),
          Icons.remove_shopping_cart_outlined, const Color(0xFF9C948C)),
      _StatCardData('Low Stock', products.lowStockCount.toDouble(),
          Icons.warning_amber_rounded, const Color(0xFFE08A2E)),
      _StatCardData('Expiring Soon', products.expiringSoonCount.toDouble(),
          Icons.hourglass_bottom_rounded, const Color(0xFFE08A2E)),
      _StatCardData('Expired', products.expiredCount.toDouble(),
          Icons.dangerous_outlined, const Color(0xFFE0483E)),
      _StatCardData('Inventory Value', products.totalInventoryValue,
          Icons.account_balance_wallet_outlined, scheme.primary, isCurrency: true),
      _StatCardData('Expected Profit', products.totalExpectedProfit,
          Icons.trending_up_rounded, const Color(0xFF2E9E5B), isCurrency: true),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 400)),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) => _StatCard(data: stats[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductListPage()),
        ),
        icon: const Icon(Icons.list_alt_rounded),
        label: const Text('View Products'),
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;
  _StatCardData(this.label, this.value, this.icon, this.color, {this.isCurrency = false});
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: data.value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              final display = data.isCurrency
                  ? '\$${value.toStringAsFixed(0)}'
                  : value.toStringAsFixed(0);
              return Text(display,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800));
            },
          ),
          const SizedBox(height: 2),
          Text(data.label,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}