import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';

class ActivateScreen extends StatefulWidget {
  const ActivateScreen({super.key});

  @override
  State<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends State<ActivateScreen> {
  final _codeController = TextEditingController();

  void _activate() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال كود التفعيل')));
      return;
    }
    context.read<AuthBloc>().add(ActivateRequested(code));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل كود')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthAuthenticated) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.key, size: 48, color: AppColors.electric),
              const SizedBox(height: 16),
              const Text('تفعيل الحساب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              const SizedBox(height: 8),
              const Text('أدخل كود التفعيل الذي حصلت عليه', style: TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'كود التفعيل', prefixIcon: Icon(Icons.vpn_key_outlined)),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) return const LoadingWidget(message: 'جاري التفعيل...');
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _activate, child: const Text('تفعيل')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
