import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'welcome_page.dart';
import 'manage_employees_page.dart';
import 'inventory_dashboard_page.dart';

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
            _DashboardTile(
              icon: Icons.inventory_2_rounded,
              label: 'Inventory',
              subtitle: 'Products, stock levels, and analytics',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryDashboardPage()),
              ),
            ),
            _DashboardTile(
              icon: Icons.people_alt_rounded,
              label: 'Manage Employees',
              subtitle: 'Add, view, and promote employees',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageEmployeesPage()),
              ),
            ),
            _DashboardTile(
              icon: Icons.bar_chart_rounded,
              label: 'Sales Reports',
              subtitle: 'View shop sales performance',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sales reports — coming soon')),
              ),
            ),
            _DashboardTile(
              icon: Icons.storefront_rounded,
              label: 'Shop Data',
              subtitle: 'Manage inventory and shop settings',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shop data — coming soon')),
              ),
            ),
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