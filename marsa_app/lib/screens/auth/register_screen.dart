import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'كلمة المرور غير متطابقة');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await _auth.registerTrial({
      'store_name': _storeNameController.text.trim(),
      'owner_name': _ownerNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'address': '',
      'city': '',
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => _error = result.errorMessage);
    }
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
                const Text('فترة تجريبية مجانية لمدة 14 يوم', style: TextStyle(fontSize: 15, color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                const SizedBox(height: 24),

                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger, fontFamily: 'Tajawal', fontSize: 14)),
                  ),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _storeNameController,
                        decoration: const InputDecoration(labelText: 'اسم المحل *', prefixIcon: Icon(Icons.store_outlined)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المحل مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(labelText: 'اسم المالك *', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المالك مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني *', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
                          if (!v.contains('@')) return 'البريد الإلكتروني غير صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف *', prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'اسم المستخدم *', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المستخدم مطلوب' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'كلمة المرور مطلوبة' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'تأكيد كلمة المرور مطلوب' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('ابدأ التجربة المجانية', style: TextStyle(fontSize: 16, fontFamily: 'Tajawal')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب؟ ', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.textSecondaryLight)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('تسجيل الدخول', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.electric, fontWeight: FontWeight.w700)),
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
