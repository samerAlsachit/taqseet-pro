import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/inventory_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _lowStockAlertController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _installmentPriceController = TextEditingController();
  final _cashPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  // Currency: 'IQD' for Dinar, 'USD' for Dollar
  String _currency = 'IQD';

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.product!.name;
      _categoryController.text = widget.product!.category ?? '';
      _quantityController.text = widget.product!.quantity.toString();
      _lowStockAlertController.text = '5';
      _purchasePriceController.text = widget.product!.costPrice.toString();
      _installmentPriceController.text =
          widget.product!.installmentPrice.toString();
      _cashPriceController.text = widget.product!.cashPrice.toString();
      _descriptionController.text = widget.product!.description ?? '';
      _imageUrl = widget.product!.imageUrl;
      _currency = 'IQD';
    } else {
      _quantityController.text = '0';
      _lowStockAlertController.text = '5';
      _purchasePriceController.text = '0';
      _installmentPriceController.text = '0';
      _cashPriceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _lowStockAlertController.dispose();
    _purchasePriceController.dispose();
    _installmentPriceController.dispose();
    _cashPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<InventoryProvider>();

      final data = {
        'name': _nameController.text.trim(),
        'currency': _currency,
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'low_stock_alert': int.tryParse(_lowStockAlertController.text) ?? 5,
        'cost_price': double.tryParse(_purchasePriceController.text) ?? 0,
        'installment_price':
            double.tryParse(_installmentPriceController.text) ?? 0,
        'cash_price': double.tryParse(_cashPriceController.text) ?? 0,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'image_url': _imageUrl,
      };

      debugPrint('📤 Saving product data: $data');

      bool success;
      if (isEditing) {
        success = await provider.updateProduct(
          widget.product!.copyWith(
            name: data['name']?.toString() ?? '',
            category: data['category']?.toString().isEmpty == true
                ? null
                : data['category']?.toString(),
            quantity: data['quantity'] is int
                ? data['quantity'] as int
                : int.tryParse(data['quantity'].toString()) ?? 0,
            cashPrice: data['cash_price'] is double
                ? data['cash_price'] as double
                : double.tryParse(data['cash_price'].toString()) ?? 0.0,
            installmentPrice: data['installment_price'] is double
                ? data['installment_price'] as double
                : double.tryParse(data['installment_price'].toString()) ?? 0.0,
            costPrice: data['cost_price'] is double
                ? data['cost_price'] as double
                : double.tryParse(data['cost_price'].toString()) ?? 0.0,
            description: data['description']?.toString().isEmpty == true
                ? null
                : data['description']?.toString(),
            imageUrl: data['image_url']?.toString().isEmpty == true
                ? null
                : data['image_url']?.toString(),
          ),
        );
      } else {
        success = await provider.addProduct(
          ProductModel(
            id: '',
            name: data['name']?.toString() ?? '',
            category: data['category']?.toString().isEmpty == true
                ? null
                : data['category']?.toString(),
            quantity: data['quantity'] is int
                ? data['quantity'] as int
                : int.tryParse(data['quantity'].toString()) ?? 0,
            cashPrice: data['cash_price'] is double
                ? data['cash_price'] as double
                : double.tryParse(data['cash_price'].toString()) ?? 0.0,
            installmentPrice: data['installment_price'] is double
                ? data['installment_price'] as double
                : double.tryParse(data['installment_price'].toString()) ?? 0.0,
            costPrice: data['cost_price'] is double
                ? data['cost_price'] as double
                : double.tryParse(data['cost_price'].toString()) ?? 0.0,
            description: data['description']?.toString().isEmpty == true
                ? null
                : data['description']?.toString(),
            imageUrl: data['image_url']?.toString().isEmpty == true
                ? null
                : data['image_url']?.toString(),
          ),
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'فشل في حفظ المنتج',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل منتج' : 'إضافة منتج',
          style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Product Name
              _buildTextField(
                controller: _nameController,
                label: 'اسم المنتج',
                icon: Icons.shopping_bag,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم المنتج';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Currency Selection
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.currency_exchange,
                              color: AppColors.navy, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'العملة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'دينار عراقي',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', color: Colors.black87),
                            ),
                            value: 'IQD',
                            groupValue: _currency,
                            activeColor: AppColors.electric,
                            onChanged: (value) {
                              setState(() => _currency = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'دولار',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', color: Colors.black87),
                            ),
                            value: 'USD',
                            groupValue: _currency,
                            activeColor: AppColors.electric,
                            onChanged: (value) {
                              setState(() => _currency = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Category
              _buildTextField(
                controller: _categoryController,
                label: 'الفئة',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),

              // 4. Quantity
              _buildTextField(
                controller: _quantityController,
                label: 'الكمية',
                icon: Icons.inventory,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // 5. Low Stock Alert
              _buildTextField(
                controller: _lowStockAlertController,
                label: 'حد تنبيه المخزون',
                icon: Icons.notification_important,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // 6. Purchase Price
              _buildTextField(
                controller: _purchasePriceController,
                label: 'سعر الشراء',
                icon: Icons.shopping_cart,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // 7. Installment Price
              _buildTextField(
                controller: _installmentPriceController,
                label: 'سعر البيع بالأقساط',
                icon: Icons.payment,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // 8. Cash Price
              _buildTextField(
                controller: _cashPriceController,
                label: 'سعر البيع النقدي',
                icon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // 9. Description
              _buildTextField(
                controller: _descriptionController,
                label: 'وصف المنتج',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electric,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'تحديث المنتج' : 'إضافة المنتج',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            color: Colors.white,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        color: Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.black54,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.navy),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.electric),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
