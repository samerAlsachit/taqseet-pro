import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  bool _isLoading = false;

  // Basic fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Stock fields
  final _quantityController = TextEditingController();
  final _stockAlertController = TextEditingController();

  // Price fields
  final _purchasePriceController = TextEditingController();
  final _cashSalePriceController = TextEditingController();
  final _installmentSalePriceController = TextEditingController();

  // Currency selection
  bool _isIQD = true;

  String get _currencySymbol => _isIQD ? 'د.ع' : '\$';
  IconData get _currencyIcon =>
      _isIQD ? LucideIcons.banknote : LucideIcons.dollarSign;

  // Check if we're in edit mode
  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if in edit mode
    if (_isEditMode) {
      _nameController.text = widget.product!.name;
      _quantityController.text = widget.product!.stockQuantity.toString();
      // Determine currency based on which price is set
      if (widget.product!.priceIQD > 0 && widget.product!.priceUSD == 0) {
        _isIQD = true;
        _cashSalePriceController.text = widget.product!.priceIQD
            .toStringAsFixed(0);
      } else if (widget.product!.priceUSD > 0 &&
          widget.product!.priceIQD == 0) {
        _isIQD = false;
        _cashSalePriceController.text = widget.product!.priceUSD
            .toStringAsFixed(0);
      } else {
        // Both or none - default to IQD
        _isIQD = true;
        _cashSalePriceController.text = widget.product!.priceIQD > 0
            ? widget.product!.priceIQD.toStringAsFixed(0)
            : widget.product!.priceUSD.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _stockAlertController.dispose();
    _purchasePriceController.dispose();
    _cashSalePriceController.dispose();
    _installmentSalePriceController.dispose();
    super.dispose();
  }

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
        title: Text(
          _isEditMode ? 'تعديل المنتج' : 'إضافة منتج جديد',
          style: const TextStyle(
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
              // Product Name
              _buildInputField(
                label: 'اسم المنتج',
                controller: _nameController,
                icon: LucideIcons.package,
                hint: 'أدخل اسم المنتج',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم المنتج مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Currency Toggle
              _buildCurrencyToggle(),
              const SizedBox(height: 24),

              // Stock Alert Threshold
              _buildInputField(
                label: 'حد تنبيه المخزون',
                controller: _stockAlertController,
                icon: LucideIcons.alertTriangle,
                hint: '5',
                keyboardType: TextInputType.number,
                suffixText: 'قطعة',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'حد التنبيه مطلوب';
                  }
                  if (int.tryParse(value) == null) {
                    return 'أدخل رقماً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section: Pricing
              _buildSectionTitle('البيانات المالية'),
              const SizedBox(height: 16),

              // Purchase Price
              _buildInputField(
                label: 'سعر الشراء',
                controller: _purchasePriceController,
                icon: _currencyIcon,
                hint: '0',
                keyboardType: TextInputType.number,
                suffixText: _currencySymbol,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'سعر الشراء مطلوب';
                  }
                  if (double.tryParse(value) == null) {
                    return 'أدخل رقماً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cash Sale Price
              _buildInputField(
                label: 'سعر البيع نقداً',
                controller: _cashSalePriceController,
                icon: LucideIcons.banknote,
                hint: '0',
                keyboardType: TextInputType.number,
                suffixText: _currencySymbol,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'سعر البيع نقداً مطلوب';
                  }
                  if (double.tryParse(value) == null) {
                    return 'أدخل رقماً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Installment Sale Price
              _buildInputField(
                label: 'سعر البيع بالأقساط',
                controller: _installmentSalePriceController,
                icon: LucideIcons.calendar,
                hint: '0',
                keyboardType: TextInputType.number,
                suffixText: _currencySymbol,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'سعر البيع بالأقساط مطلوب';
                  }
                  if (double.tryParse(value) == null) {
                    return 'أدخل رقماً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section: Additional Details
              _buildSectionTitle('تفاصيل إضافية'),
              const SizedBox(height: 16),

              // Current Quantity
              _buildInputField(
                label: 'الكمية الحالية',
                controller: _quantityController,
                icon: LucideIcons.archive,
                hint: '0',
                keyboardType: TextInputType.number,
                suffixText: 'قطعة',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الكمية مطلوبة';
                  }
                  if (int.tryParse(value) == null) {
                    return 'أدخل رقماً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildInputField(
                label: 'وصف المنتج',
                controller: _descriptionController,
                icon: LucideIcons.fileText,
                hint: 'أدخل وصف المنتج (اختياري)',
                maxLines: 4,
              ),
              const SizedBox(height: 40),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'عملة المنتج',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIQD = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isIQD
                          ? const Color(0xFF0A192F)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.banknote,
                          color: _isIQD
                              ? Colors.white
                              : const Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'دينار عراقي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isIQD
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIQD = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isIQD
                          ? const Color(0xFF0A192F)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.dollarSign,
                          color: !_isIQD
                              ? Colors.white
                              : const Color(0xFF64748B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'دولار أمريكي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !_isIQD
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    String? Function(String?)? validator,
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
          textAlign: TextAlign.right,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: Color(0xFF0A192F),
          ),
          validator: validator,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);

                  final product = ProductModel(
                    id: _isEditMode
                        ? widget.product!.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text,
                    quantity: int.parse(_quantityController.text),
                    sellPriceCashIqd: _isIQD
                        ? double.parse(_cashSalePriceController.text)
                        : 0,
                    sellPriceCashUsd: !_isIQD
                        ? double.parse(_cashSalePriceController.text)
                        : 0,
                    storeId: '', // Will be set by backend
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  // Save to API and local DB
                  final result = _isEditMode
                      ? await _productService.updateProduct(product)
                      : await _productService.createProduct(product);

                  setState(() => _isLoading = false);

                  if (result.success) {
                    // Sync all products to ensure consistency
                    await _productService.syncProducts();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.message,
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      );

                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          Navigator.pop(context, product);
                        }
                      });
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.message,
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A192F),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.check, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'تحديث المنتج' : 'حفظ المنتج',
                    style: const TextStyle(
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
