import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'welcome_page.dart';

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
      body: Center(
        child: Text(
          'Welcome, ${auth.userModel?.name ?? 'Employee'}!',
          style: AppText.body.copyWith(fontSize: 18),
        ),
      ),
    );
  }
}