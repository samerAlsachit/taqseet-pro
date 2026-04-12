import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkBiometricAvailability();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start animation automatically
    _animationController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricAvailable = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'استخدم بصمتك للدخول إلى متجرك',
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'التحقق بالبصمة',
            cancelButton: 'إلغاء',
            biometricHint: 'المس جهاز الاستشعار',
            biometricNotRecognized: 'البصمة غير معروفة، حاول مرة أخرى',
            biometricRequiredTitle: 'يرجى استخدام البصمة',
            biometricSuccess: 'تم التعرف على البصمة',
            deviceCredentialsRequiredTitle: 'يرجى إدخال بيانات الجهاز',
            deviceCredentialsSetupDescription: 'يرجى إعداد بيانات الجهاز',
            goToSettingsButton: 'الإعدادات',
            goToSettingsDescription: 'يرجى إعداد البصمة في إعدادات الجهاز',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate && mounted) {
        // Mock successful biometric login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الدخول بالبصمة بنجاح!',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Color(0xFF0A192F),
          ),
        );

        // Navigate to main navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل التحقق بالبصمة: $e',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Mock function to check subscription status
  Future<Map<String, dynamic>> _checkSubscriptionStatus(String email) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock logic: emails containing "expired" will have expired subscription
    if (email.toLowerCase().contains('expired')) {
      return {
        'isActive': false,
        'message': 'انتهت فترة التجربة، يرجى تفعيل الكود من لوحة تحكم الويب',
      };
    }

    // Default: active subscription
    return {'isActive': true, 'message': 'تم تسجيل الدخول بنجاح'};
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check subscription status
      final status = await _checkSubscriptionStatus(_emailController.text);

      if (mounted) {
        if (status['isActive'] == true) {
          // Active subscription - navigate to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status['message'],
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: const Color(0xFF0A192F),
            ),
          );

          // Navigate to main navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        } else {
          // Expired subscription - show error
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'انتهى الاشتراك',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A192F),
                    ),
                  ),
                ],
              ),
              content: Text(
                status['message'],
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'فهمت',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF0A192F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'نسيت كلمة المرور؟',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A192F),
          ),
        ),
        content: const Text(
          'يرجى زيارة موقعنا على الويب لإعادة تعيين كلمة المرور الخاصة بك.',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إغلاق',
              style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A192F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'زيارة الموقع',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Logo (Animated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A192F),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo Container with Fade and Slide Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.anchor,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title with Fade Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'مرساة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle with Fade Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'نظام إدارة الأقساط الذكي',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Login Form Section
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أهلاً بعودتك! يرجى إدخال بياناتك للمتابعة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email/Phone Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني أو رقم الهاتف',
                        hint: 'example@email.com أو 0770XXXXXXX',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '••••••••',
                        icon: LucideIcons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          if (value.length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember Me
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                activeColor: const Color(0xFF0A192F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Text(
                                'تذكرني',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),

                          // Forgot Password
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                color: Color(0xFF0A192F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A192F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.logIn, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Biometric Login Button (only if available)
                      if (_isBiometricAvailable) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _authenticateWithBiometric,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0A192F),
                              side: const BorderSide(
                                color: Color(0xFF0A192F),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              LucideIcons.fingerprint,
                              size: 24,
                              color: Color(0xFF0A192F),
                            ),
                            label: const Text(
                              'الدخول بالبصمة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sign Up Promotion
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'قم بزيارة موقعنا لتفعيل متجرك وبدء التجربة المجانية (14 يوم)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // Open website
                      },
                      icon: const Icon(
                        LucideIcons.globe,
                        color: Color(0xFF4A9EFF),
                        size: 18,
                      ),
                      label: const Text(
                        'زيارة موقع مرساة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Color(0xFF4A9EFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A192F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Tajawal',
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0A192F),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
