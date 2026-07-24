import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;
  final VoidCallback? onBack;
  final double heroHeightFraction;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    this.onBack,
    this.heroHeightFraction = 0.32,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.sheet,
      body: Column(
        children: [
          // Gradient hero band - using Expanded with flex to fill the top portion
          Expanded(
            flex: (heroHeightFraction * 100).round(),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onBack != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: onBack,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      Text(title, style: AppText.displayOnGradient),
                      const SizedBox(height: 6),
                      Text(subtitle, style: AppText.subtitleOnGradient),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // White sheet with rounded top
          Expanded(
            flex: 100 - (heroHeightFraction * 100).round(),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.sheet,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: form,
              ),
            ),
          ),
        ],
      ),
    );
  }
}