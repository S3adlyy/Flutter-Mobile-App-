import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'welcome_page.dart';
import 'product_list_page.dart';

class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.sheet,
      appBar: AppBar(
        backgroundColor: AppColors.sheet,
        elevation: 0,
        title: Text('Home', style: AppText.display.copyWith(fontSize: 20)),
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
            Text('Welcome, ${auth.userModel?.name ?? 'Employee'}!',
                style: AppText.body.copyWith(color: AppColors.taupe)),
            const SizedBox(height: 20),
            Card(
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
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 22),
                ),
                title: Text('Browse Products', style: AppText.label.copyWith(fontSize: 15)),
                subtitle: Text('View stock, prices, and expiration dates',
                    style: AppText.body.copyWith(fontSize: 12.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.taupe),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}