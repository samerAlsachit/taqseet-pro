import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _biometric = BiometricService();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _bioAvailable = false;
  String? _savedUsername;

  // Forgot modals
  final _forgotEmailController = TextEditingController();
  final _forgotUsernameController = TextEditingController();
  bool _forgotLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled = await _biometric.isEnabled();
    final username = await _auth.getSavedUsername();
    if (mounted && enabled && username != null && username.isNotEmpty) {
      setState(() { _bioAvailable = true; _savedUsername = username; });
    }
  }

  Future<void> _biometricLogin() async {
    final authed = await _biometric.authenticate();
    if (!authed || !mounted) return;
    _usernameController.text = _savedUsername ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم التحقق من البصمة، أدخل كلمة المرور')),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    _forgotUsernameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    final result = await _auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      _offerBiometric();
    } else {
      setState(() => _error = result.errorMessage);
    }
  }

  Future<void> _offerBiometric() async {
    final biometric = BiometricService();
    final available = await biometric.isAvailable();
    if (!available) {
      _goHome();
      return;
    }
    final already = await biometric.isEnabled();
    if (already) {
      _goHome();
      return;
    }

    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تفعيل البصمة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
        content: const Text('هل تريد تفعيل تسجيل الدخول ببصمة الإصبع للمرة القادمة؟', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تخطي', style: TextStyle(fontFamily: 'Tajawal'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تفعيل', style: TextStyle(fontFamily: 'Tajawal'))),
        ],
      ),
    );

    if (enable == true) {
      await biometric.setEnabled(true);
      await biometric.authenticate();
    }

    _goHome();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showForgotUsername() {
    _forgotEmailController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('استعادة اسم المستخدم', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل بريدك الإلكتروني', style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              TextField(
                controller: _forgotEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _forgotLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              onPressed: _forgotEmailController.text.isEmpty || _forgotLoading ? null : () async {
                setDialogState(() => _forgotLoading = true);
                // TODO: API call for forgot username
                await Future.delayed(const Duration(seconds: 1));
                setDialogState(() => _forgotLoading = false);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('تم الإرسال، تحقق من بريدك الإلكتروني')),
                  );
                }
              },
              child: _forgotLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إرسال', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPassword() {
    _forgotUsernameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('استعادة كلمة المرور', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل اسم المستخدم الخاص بك', style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              TextField(
                controller: _forgotUsernameController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم', prefixIcon: Icon(Icons.person_outline)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _forgotLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              onPressed: _forgotUsernameController.text.isEmpty || _forgotLoading ? null : () async {
                setDialogState(() => _forgotLoading = true);
                // TODO: API call for forgot password
                await Future.delayed(const Duration(seconds: 1));
                setDialogState(() => _forgotLoading = false);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('تم الإرسال، تحقق من بريدك الإلكتروني')),
                  );
                }
              },
              child: _forgotLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إرسال', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
                  child: const Icon(Icons.anchor, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('مرساة', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.navy, fontFamily: 'Tajawal')),
                const SizedBox(height: 6),
                const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),

                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger, fontFamily: 'Tajawal', fontSize: 14)),
                  ),

                if (_bioAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 4),
                    child: SizedBox(
                      width: double.infinity, height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _biometricLogin,
                        icon: const Icon(Icons.fingerprint, size: 22),
                        label: const Text('تسجيل الدخول بالبصمة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.electric,
                          side: BorderSide(color: AppColors.electric.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'اسم المستخدم', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المستخدم مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'كلمة المرور مطلوبة' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(onPressed: _showForgotUsername, child: const Text('نسيت اسم المستخدم؟', style: TextStyle(fontSize: 13, fontFamily: 'Tajawal', color: AppColors.electric))),
                          const Spacer(),
                          TextButton(onPressed: _showForgotPassword, child: const Text('نسيت كلمة المرور؟', style: TextStyle(fontSize: 13, fontFamily: 'Tajawal', color: AppColors.electric))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontFamily: 'Tajawal')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟ ', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.textSecondaryLight)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('سجل الآن', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.electric, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
