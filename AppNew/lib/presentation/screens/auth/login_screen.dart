import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _showBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final hasToken = await _authService.hasToken();
    if (hasToken && mounted) {
      final canBio = await _authService.canCheckBiometrics();
      if (canBio && mounted) {
        setState(() => _showBiometric = true);
      }
    }
  }

  Future<void> _biometricLogin() async {
    final authenticated = await _authService.authenticateWithBiometrics();
    if (authenticated && mounted) {
      final token = await _authService.getToken();
      if (token != null && mounted) {
        context.read<AuthBloc>().add(CheckAuth());
      }
    }
  }

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور')));
      return;
    }
    context.read<AuthBloc>().add(LoginRequested(username, password));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthAuthenticated) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                  child: const Icon(Icons.anchor, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('مرساة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                const Text('تسجيل الدخول', style: TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                const SizedBox(height: 32),
                if (_showBiometric) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _biometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('تسجيل الدخول بالبصمة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.electric,
                        side: const BorderSide(color: AppColors.electric),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('أو', style: TextStyle(color: AppColors.textSecondaryLight))),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) return const LoadingWidget(message: 'جاري تسجيل الدخول...');
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _login, child: const Text('تسجيل الدخول')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('نسيت اسم المستخدم؟')),
                    TextButton(onPressed: () {}, child: const Text('نسيت كلمة المرور؟')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟', style: TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('سجل الآن'),
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
