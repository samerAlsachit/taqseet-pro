import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/activate_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            // Top section with logo
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electric.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'مرساة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // App name
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
                  ],
                ),
              ),
            ),

            // Features section
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.shield_outlined,
                      title: 'نظام آمن وموثوق',
                      description: 'حماية كاملة لبياناتك وعملائك',
                      delay: 600.ms,
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.offline_bolt_outlined,
                      title: 'يعمل بدون إنترنت',
                      description: 'استخدم التطبيق في أي وقت وأي مكان',
                      delay: 800.ms,
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.sync_outlined,
                      title: 'مزامنة تلقائية',
                      description: 'مزامنة ذكية عند توفر الإنترنت',
                      delay: 1000.ms,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section with buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 1200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.5, end: 0),

                    const SizedBox(height: 12),

                    // Activate account button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ActivateScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side:
                              const BorderSide(color: AppColors.navy, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'تفعيل حساب جديد',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 1300.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.5, end: 0),

                    const SizedBox(height: 16),

                    // Trial text
                    TextButton(
                      onPressed: () {
                        // Navigate to trial signup
                      },
                      child: const Text(
                        'تجربة مجانية لمدة 14 يوم',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: AppColors.electric,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ).animate(delay: 1400.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 8),

                    // Support contact
                    const Text(
                      'للمساعدة: support@marsa.app',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ).animate(delay: 1500.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Duration delay,
  }) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.electric.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppColors.electric,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.3, end: 0);
  }
}
