import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ActivateScreen extends StatefulWidget {
  const ActivateScreen({super.key});

  @override
  State<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends State<ActivateScreen> {
  final _licenseController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() => _isLoading = true);
    // TODO: Implement activation logic
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'تفعيل الحساب',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'أدخل مفتاح الترخيص لتفعيل حسابك',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 48),

              // License key field
              TextField(
                controller: _licenseController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'مفتاح الترخيص',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.key, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Activate button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _activate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electric,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تفعيل الحساب',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Help text
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to contact support
                  },
                  child: const Text(
                    'للحصول على مفتاح ترخيص، تواصل مع الدعم',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
