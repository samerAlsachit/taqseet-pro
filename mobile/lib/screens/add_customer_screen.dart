import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/customer_model.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

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
          'إضافة عميل جديد',
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
                label: 'اسم العميل',
                controller: _nameController,
                icon: LucideIcons.user,
                hint: 'أدخل اسم العميل الكامل',
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'رقم الهاتف',
                controller: _phoneController,
                icon: LucideIcons.phone,
                hint: 'مثال: 0770 123 4567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'العنوان',
                controller: _addressController,
                icon: LucideIcons.mapPin,
                hint: 'أدخل عنوان العميل',
                maxLines: 2,
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
    int maxLines = 1,
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
          maxLines: maxLines,
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
            final customer = CustomerModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم إضافة العميل بنجاح!',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: Color(0xFF0A192F),
              ),
            );
            
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pop(context, customer);
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
              'حفظ العميل',
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
