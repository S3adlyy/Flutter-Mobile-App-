import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../theme/app_theme.dart';

/// Admin-only screen. This screen is only ever reached through
/// AdminDashboard, which itself is only reached through RoleGuard when
/// userModel.role == 'admin' — so no extra role check is needed here,
/// but the REAL enforcement is the Firestore security rules, which will
/// reject the `updateRole` write server-side if the caller isn't an admin,
/// even if someone tried to reach this screen directly.
class ManageEmployeesPage extends StatefulWidget {
  const ManageEmployeesPage({super.key});

  @override
  State<ManageEmployeesPage> createState() => _ManageEmployeesPageState();
}

class _ManageEmployeesPageState extends State<ManageEmployeesPage> {
  final _userRepository = UserRepository();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _userRepository.getAllUsers();
  }

  void _refresh() {
    setState(() {
      _usersFuture = _userRepository.getAllUsers();
    });
  }

  Future<void> _promote(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin?'),
        content: Text(
            '${user.name} will gain full admin access, including the ability to promote other employees.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Promote')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userRepository.updateRole(targetUid: user.uid, newRole: 'admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} promoted to admin')),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to promote: check Firestore rules'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheet,
      appBar: AppBar(
        backgroundColor: AppColors.sheet,
        elevation: 0,
        title: Text('Manage Employees',
            style: AppText.display.copyWith(fontSize: 18)),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                elevation: 0,
                color: AppColors.fieldFill,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text(user.name, style: AppText.label),
                  subtitle: Text(user.email, style: AppText.body),
                  trailing: user.isAdmin
                      ? Chip(
                    label: const Text('Admin'),
                    backgroundColor: AppColors.amber.withOpacity(0.15),
                    labelStyle: AppText.body.copyWith(
                        color: AppColors.amber, fontWeight: FontWeight.w700),
                  )
                      : TextButton(
                    onPressed: () => _promote(user),
                    child: const Text('Promote'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}