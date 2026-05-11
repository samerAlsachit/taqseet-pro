import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product_bloc/product_bloc.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _qtyController = TextEditingController();
  final _lowStockAlertController = TextEditingController(text: '5');
  final _costPriceController = TextEditingController();
  final _sellPriceCashController = TextEditingController();
  final _sellPriceInstallController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _currency = 'IQD';

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final currency = _currency;
    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    final sellPriceCash = double.tryParse(_sellPriceCashController.text) ?? 0;
    final sellPriceInstall = double.tryParse(_sellPriceInstallController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final lowStock = int.tryParse(_lowStockAlertController.text) ?? 5;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'category': _categoryController.text.trim(),
      'quantity': qty,
      'low_stock_alert': lowStock,
      'currency': currency,
    };

    if (currency == 'IQD') {
      data['cost_price_iqd'] = costPrice;
      data['sell_price_cash_iqd'] = sellPriceCash;
      data['sell_price_install_iqd'] = sellPriceInstall;
      data['cost_price_usd'] = 0;
      data['sell_price_cash_usd'] = 0;
      data['sell_price_install_usd'] = 0;
    } else {
      data['cost_price_usd'] = costPrice;
      data['sell_price_cash_usd'] = sellPriceCash;
      data['sell_price_install_usd'] = sellPriceInstall;
      data['cost_price_iqd'] = 0;
      data['sell_price_cash_iqd'] = 0;
      data['sell_price_install_iqd'] = 0;
    }

    final isEdit = widget.productId != null;
    if (isEdit) {
      context.read<ProductBloc>().add(UpdateProduct(widget.productId!, data));
    } else {
      context.read<ProductBloc>().add(CreateProduct(data));
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _qtyController.dispose();
    _lowStockAlertController.dispose();
    _costPriceController.dispose();
    _sellPriceCashController.dispose();
    _sellPriceInstallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productId != null ? 'تعديل منتج' : 'إضافة منتج')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج', prefixIcon: Icon(Icons.inventory_2)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المنتج مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'الوصف', prefixIcon: Icon(Icons.description)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'الفئة', prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(labelText: 'الكمية', prefixIcon: Icon(Icons.numbers)),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الكمية مطلوبة' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lowStockAlertController,
                      decoration: const InputDecoration(labelText: 'حد التنبيه', prefixIcon: Icon(Icons.warning_amber)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('عملة المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'IQD',
                      groupValue: _currency,
                      title: const Text('IQD', style: TextStyle(fontFamily: 'Tajawal')),
                      onChanged: (v) => setState(() => _currency = v ?? 'IQD'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'USD',
                      groupValue: _currency,
                      title: const Text('USD', style: TextStyle(fontFamily: 'Tajawal')),
                      onChanged: (v) => setState(() => _currency = v ?? 'IQD'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costPriceController,
                decoration: InputDecoration(labelText: 'سعر الشراء ($_currency)', prefixIcon: const Icon(Icons.shopping_cart)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellPriceCashController,
                decoration: InputDecoration(labelText: 'سعر البيع نقداً ($_currency)', prefixIcon: const Icon(Icons.monetization_on)),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'سعر البيع مطلوب';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'سعر صحيح مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellPriceInstallController,
                decoration: InputDecoration(labelText: 'سعر البيع بالقسط ($_currency)', prefixIcon: const Icon(Icons.schedule)),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'سعر القسط مطلوب';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'سعر صحيح مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _submit, child: Text(widget.productId != null ? 'حفظ التعديلات' : 'إضافة المنتج')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
