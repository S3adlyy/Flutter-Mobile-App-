import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'welcome_page.dart';
import 'manage_employees_page.dart';
import 'manage_clients_page.dart';
import 'inventory_dashboard_page.dart';
import 'add_purchase_page.dart';
import 'purchase_history_page.dart';
import 'add_sale_page.dart';
import 'sale_history_page.dart'; // Add this import

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.sheet,
      appBar: AppBar(
        backgroundColor: AppColors.sheet,
        elevation: 0,
        title: Text('Admin Dashboard',
            style: AppText.display.copyWith(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.ink),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${auth.userModel?.name ?? 'Admin'}',
                style: AppText.body.copyWith(color: AppColors.taupe)),
            const SizedBox(height: 20),

            // Inventory
            _DashboardTile(
              icon: Icons.inventory_2_rounded,
              label: 'Inventory',
              subtitle: 'Products, stock levels, and analytics',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryDashboardPage()),
              ),
            ),

            // Sales Management
            _DashboardTile(
              icon: Icons.sell_rounded,
              label: 'Sales Management',
              subtitle: 'Record sales, manage clients, view history',
              onTap: () => _showSaleOptions(context),
            ),

            // Purchase Management
            _DashboardTile(
              icon: Icons.shopping_cart_rounded,
              label: 'Purchase Management',
              subtitle: 'Record supplier purchases and view history',
              onTap: () => _showPurchaseOptions(context),
            ),

            // Manage Employees
            _DashboardTile(
              icon: Icons.people_alt_rounded,
              label: 'Manage Employees',
              subtitle: 'Add, view, and promote employees',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageEmployeesPage()),
              ),
            ),

            // Manage Clients
            _DashboardTile(
              icon: Icons.people_rounded,
              label: 'Manage Clients',
              subtitle: 'Add, view, and manage clients',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageClientsPage()),
              ),
            ),

            // Sales Reports (Coming Soon)
            _DashboardTile(
              icon: Icons.bar_chart_rounded,
              label: 'Sales Reports',
              subtitle: 'View shop sales performance',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sales reports — coming soon')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.taupe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // New Sale
            ListTile(
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
              ),
              title: Text('New Sale', style: AppText.label.copyWith(fontSize: 15)),
              subtitle: Text('Record a new client sale',
                  style: AppText.body.copyWith(fontSize: 12.5)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSalePage()),
                );
              },
            ),
            // Manage Clients
            ListTile(
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.taupe.withOpacity(0.2)),
                ),
                child: const Icon(Icons.people_rounded, color: AppColors.ink, size: 22),
              ),
              title: Text('Manage Clients', style: AppText.label.copyWith(fontSize: 15)),
              subtitle: Text('Add, view, and manage clients',
                  style: AppText.body.copyWith(fontSize: 12.5)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageClientsPage()),
                );
              },
            ),
            // Sales History
            ListTile(
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.taupe.withOpacity(0.2)),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.ink, size: 22),
              ),
              title: Text('Sales History', style: AppText.label.copyWith(fontSize: 15)),
              subtitle: Text('View and manage past sales',
                  style: AppText.body.copyWith(fontSize: 12.5)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SaleHistoryPage()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPurchaseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.taupe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // New Purchase
            ListTile(
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
              ),
              title: Text('New Purchase', style: AppText.label.copyWith(fontSize: 15)),
              subtitle: Text('Record a new supplier purchase',
                  style: AppText.body.copyWith(fontSize: 12.5)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPurchasePage()),
                );
              },
            ),
            // Purchase History
            ListTile(
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.taupe.withOpacity(0.2)),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.ink, size: 22),
              ),
              title: Text('Purchase History', style: AppText.label.copyWith(fontSize: 15)),
              subtitle: Text('View and manage past purchases',
                  style: AppText.body.copyWith(fontSize: 12.5)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseHistoryPage()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: AppColors.fieldFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(label, style: AppText.label.copyWith(fontSize: 15)),
        subtitle: Text(subtitle, style: AppText.body.copyWith(fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.taupe),
        onTap: onTap,
      ),
    );
  }
}