import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceIQDController = TextEditingController();
  final _priceUSDController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronRight, color: Color(0xFF0A192F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إضافة منتج جديد',
          style: TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: 'اسم المنتج',
                controller: _nameController,
                icon: LucideIcons.package,
                hint: 'أدخل اسم المنتج',
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'الكمية في المخزن',
                controller: _stockController,
                icon: LucideIcons.archive,
                hint: '0',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'السعر (د.ع)',
                      controller: _priceIQDController,
                      icon: LucideIcons.banknote,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffixText: 'د.ع',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      label: 'السعر (\$)',
                      controller: _priceUSDController,
                      icon: LucideIcons.dollarSign,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffixText: '\$',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: Color(0xFF0A192F),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'هذا الحقل مطلوب';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF0A192F), size: 20),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: Color(0xFF0A192F),
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final product = ProductModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              stockQuantity: int.parse(_stockController.text),
              priceIQD: double.parse(_priceIQDController.text),
              priceUSD: double.parse(_priceUSDController.text),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم إضافة المنتج بنجاح!',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: Color(0xFF0A192F),
              ),
            );
            
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pop(context, product);
              }
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A192F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.check, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'حفظ المنتج',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
