import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/cash_sale_bloc/cash_sale_bloc.dart';
import '../../blocs/product_bloc/product_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../data/models/product_model.dart';

class CashSaleScreen extends StatefulWidget {
  const CashSaleScreen({super.key});

  @override
  State<CashSaleScreen> createState() => _CashSaleScreenState();
}

class _CashSaleScreenState extends State<CashSaleScreen> {
  final _qtyController = TextEditingController(text: '1');
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();
  ProductModel? _selectedProduct;
  String _currency = 'IQD';

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProducts());
  }

  double get _price {
    if (_selectedProduct == null) return 0;
    if (_currency == 'IQD') return _selectedProduct!.sellPriceCashIqd ?? _selectedProduct!.priceIqd ?? 0;
    return _selectedProduct!.sellPriceCashUsd ?? _selectedProduct!.priceUsd ?? 0;
  }

  double get _total => _price * (int.tryParse(_qtyController.text) ?? 1);

  void _submit() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار منتج')));
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال كمية صحيحة')));
      return;
    }
    context.read<CashSaleBloc>().add(CreateCashSale({
      'product_id': _selectedProduct!.id,
      'quantity': qty,
      'price': _price,
      'currency': _currency,
      'customer_name': _customerNameController.text.trim(),
      'notes': _notesController.text.trim(),
    }));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيع نقدي')),
      body: BlocListener<CashSaleBloc, CashSaleState>(
        listener: (context, state) {
          if (state is CashSaleSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل البيع')));
            setState(() {
              _selectedProduct = null;
              _qtyController.text = '1';
              _customerNameController.clear();
              _notesController.clear();
            });
          } else if (state is CashSaleError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoaded) {
                    final products = state.products;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedProduct?.id,
                      decoration: const InputDecoration(labelText: 'المنتج', prefixIcon: Icon(Icons.inventory_2)),
                      items: products.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, style: const TextStyle(fontFamily: 'Tajawal')),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedProduct = products.firstWhere((p) => p.id == v);
                          _currency = _selectedProduct!.sellPriceCashIqd != null && _selectedProduct!.sellPriceCashIqd! > 0 ? 'IQD' : 'USD';
                        });
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(labelText: 'الكمية', prefixIcon: Icon(Icons.numbers)),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'العملة', prefixIcon: Icon(Icons.currency_exchange)),
                      items: const [
                        DropdownMenuItem(value: 'IQD', child: Text('IQD', style: TextStyle(fontFamily: 'Tajawal'))),
                        DropdownMenuItem(value: 'USD', child: Text('USD', style: TextStyle(fontFamily: 'Tajawal'))),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? 'IQD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('سعر الوحدة: ', style: TextStyle(fontFamily: 'Tajawal')),
                      Text('$_price $_currency', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'اسم العميل (اختياري)', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('الإجمالي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  const Spacer(),
                  Text('$_total $_currency', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.electric, fontFamily: 'Tajawal')),
                ],
              ),
              const SizedBox(height: 24),
              BlocBuilder<CashSaleBloc, CashSaleState>(
                builder: (context, state) {
                  if (state is CashSaleLoading) return const Center(child: CircularProgressIndicator());
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _submit, child: const Text('تأكيد البيع')),
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
