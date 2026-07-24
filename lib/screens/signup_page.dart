import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/role_guard.dart';

/// Public sign-up screen. Notice there is no role picker anywhere on this
/// screen, and none of the fields below map to a "role" — that's by
/// design (requirement #1). Every account created here becomes an
/// employee; AuthProvider.register() -> AuthService.registerEmployee()
/// hard-codes that, so it can't be changed by editing this screen alone.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Sign up failed'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created successfully!')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleGuard()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: 'Create Account',
      subtitle: 'Fill in your details to get started',
      onBack: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      heroHeightFraction: 0.28,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Full Name', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: AppText.body,
              decoration: authFieldDecoration(
                label: 'Jane Doe',
                icon: Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            Text('Email', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppText.body,
              decoration: authFieldDecoration(
                label: 'you@example.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            Text('Password', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppText.body,
              decoration: authFieldDecoration(
                label: '••••••••',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.taupe,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            Text('Confirm Password', style: AppText.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              style: AppText.body,
              decoration: authFieldDecoration(
                label: '••••••••',
                icon: Icons.lock_outline_rounded,
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 26),

            GradientButton(
              label: 'Register Now',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _signup,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: AppText.body),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Login',
                    style: AppText.body.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}