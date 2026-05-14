import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'activate_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  String? _biometricError;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = AuthService();
    final loggedIn = await auth.isLoggedIn();

    if (!loggedIn) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final biometric = BiometricService();
    final bioEnabled = await biometric.isEnabled();

    if (bioEnabled) {
      final authed = await biometric.authenticate();
      if (!authed) {
        if (mounted) setState(() { _biometricError = 'فشل التحقق من البصمة'; _checking = false; });
        return;
      }
    }

    if (mounted) setState(() { _checking = false; });

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.navy, Color(0xFF1A3A6B), AppColors.electric],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.anchor, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('مرساة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Tajawal')),
              const SizedBox(height: 24),
              const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
              if (_biometricError != null) ...[
                const SizedBox(height: 16),
                Text(_biometricError!, style: const TextStyle(color: Colors.white70, fontFamily: 'Tajawal', fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navy),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingContent()),
                      (route) => false,
                    );
                  },
                  child: const Text('تسجيل الدخول يدوياً', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return const LandingContent();
  }
}

class LandingContent extends StatelessWidget {
  const LandingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, Color(0xFF1A3A6B), AppColors.electric],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.anchor, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text('مرساة', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Tajawal', letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Text('نظام متكامل لإدارة الأقساط والديون\nللمحلات التجارية في العراق', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Tajawal', height: 1.6)),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navy, elevation: 4, shadowColor: AppColors.navy.withValues(alpha: 0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivateScreen())),
                        icon: const Icon(Icons.vpn_key_outlined, size: 20),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        label: const Text('تفعيل كود', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        icon: const Icon(Icons.card_giftcard_outlined, size: 20),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        label: const Text('تجربة مجانية 14 يوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Tajawal')),
                      ),
                    ),
                    const Spacer(flex: 1),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('v1.0.0', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), fontFamily: 'Tajawal')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
