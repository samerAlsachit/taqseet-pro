import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/installment_bloc/installment_bloc.dart';
import '../../blocs/customer_bloc/customer_bloc.dart';
import '../../blocs/product_bloc/product_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/product_model.dart';

class InstallmentFormScreen extends StatefulWidget {
  const InstallmentFormScreen({super.key});

  @override
  State<InstallmentFormScreen> createState() => _InstallmentFormScreenState();
}

class _InstallmentFormScreenState extends State<InstallmentFormScreen> {
  int _step = 0;
  CustomerModel? _selectedCustomer;
  final _cart = <Map<String, dynamic>>[];
  final _downPaymentController = TextEditingController();
  final _notesController = TextEditingController();
  String _frequency = 'monthly';
  String _currency = 'IQD';
  DateTime _startDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  double get _totalPrice => _cart.fold(0, (sum, item) => sum + (item['price'] as num).toDouble() * (item['quantity'] as num).toDouble());
  double get _installmentAmount {
    final total = _totalPrice;
    final down = double.tryParse(_downPaymentController.text) ?? 0;
    final financed = total - down;
    if (financed <= 0) return 0;
    final count = _cart.fold<int>(0, (sum, item) => sum + ((item['installments_count'] as num?)?.toInt() ?? 1));
    return financed / count;
  }

  void _selectCustomer() {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerPicker(onSelect: (c) => setState(() => _selectedCustomer = c)),
    );
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (ctx) => _ProductPicker(onSelect: (p) {
        setState(() {
          _cart.add({
            'product_id': p.id,
            'name': p.name,
            'quantity': 1,
            'price': p.sellPriceInstallIqd ?? p.priceIqd ?? 0,
            'currency': _currency,
            'installments_count': 1,
          });
        });
      }),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCustomer == null) return;
    if (_cart.isEmpty) return;
    final down = double.tryParse(_downPaymentController.text) ?? 0;
    final financed = _totalPrice - down;

    context.read<InstallmentBloc>().add(CreateInstallment({
      'customer_id': _selectedCustomer!.id,
      'product_id': _cart.first['product_id'],
      'products': _cart,
      'total_price': _totalPrice,
      'down_payment': down,
      'financed_amount': financed,
      'installment_amount': _installmentAmount,
      'installments_count': _cart.length,
      'frequency': _frequency,
      'start_date': _startDate.toIso8601String().split('T')[0],
      'currency': _currency,
      'notes': _notesController.text.trim(),
    }));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _downPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قسط جديد')),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['العميل', 'المنتجات', 'التفاصيل', 'معاينة'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(labels.length, (i) => Expanded(
          child: Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= _step ? AppColors.electric : AppColors.borderLight,
                ),
                child: Center(child: Text('${i + 1}', style: TextStyle(color: i <= _step ? Colors.white : AppColors.textSecondaryLight, fontFamily: 'Tajawal'))),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: const TextStyle(fontSize: 11, fontFamily: 'Tajawal')),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _stepCustomer();
      case 1: return _stepProducts();
      case 2: return _stepDetails();
      case 3: return _stepPreview();
      default: return const SizedBox();
    }
  }

  Widget _stepCustomer() {
    return Column(
      children: [
        const Text('اختيار العميل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 16),
        if (_selectedCustomer != null)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_selectedCustomer!.fullName, style: const TextStyle(fontFamily: 'Tajawal')),
              subtitle: Text(_selectedCustomer!.phone ?? '', style: const TextStyle(fontFamily: 'Tajawal')),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedCustomer = null)),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectCustomer,
              icon: const Icon(Icons.search),
              label: const Text('اختيار عميل', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ),
      ],
    );
  }

  Widget _stepProducts() {
    return Column(
      children: [
        Row(
          children: [
            const Text('المنتجات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            const Spacer(),
            TextButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add, size: 18), label: const Text('إضافة', style: TextStyle(fontFamily: 'Tajawal'))),
          ],
        ),
        const SizedBox(height: 8),
        if (_cart.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لم يتم إضافة منتجات', style: TextStyle(fontFamily: 'Tajawal', color: AppColors.textSecondaryLight)))))
        else
          ..._cart.asMap().entries.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(entry.value['name'] ?? '', style: const TextStyle(fontFamily: 'Tajawal')),
              subtitle: Text('الكمية: ${entry.value['quantity']} - ${entry.value['price']} ${_currency}', style: const TextStyle(fontFamily: 'Tajawal')),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => setState(() => _cart.removeAt(entry.key))),
            ),
          )),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('الإجمالي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            const Spacer(),
            Text('$_totalPrice $_currency', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.electric, fontFamily: 'Tajawal')),
          ],
        ),
      ],
    );
  }

  Widget _stepDetails() {
    return Column(
      children: [
        const Text('تفاصيل القسط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 16),
        TextFormField(
          controller: _downPaymentController,
          decoration: const InputDecoration(labelText: 'الدفعة الأولى', prefixIcon: Icon(Icons.payment)),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _frequency,
          decoration: const InputDecoration(labelText: 'نوع القسط', prefixIcon: Icon(Icons.calendar_today)),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('يومي', style: TextStyle(fontFamily: 'Tajawal'))),
            DropdownMenuItem(value: 'weekly', child: Text('أسبوعي', style: TextStyle(fontFamily: 'Tajawal'))),
            DropdownMenuItem(value: 'monthly', child: Text('شهري', style: TextStyle(fontFamily: 'Tajawal'))),
          ],
          onChanged: (v) => setState(() => _frequency = v ?? 'monthly'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(labelText: 'العملة', prefixIcon: Icon(Icons.currency_exchange)),
          items: const [
            DropdownMenuItem(value: 'IQD', child: Text('IQD - دينار عراقي', style: TextStyle(fontFamily: 'Tajawal'))),
            DropdownMenuItem(value: 'USD', child: Text('USD - دولار', style: TextStyle(fontFamily: 'Tajawal'))),
          ],
          onChanged: (v) => setState(() => _currency = v ?? 'IQD'),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (picked != null) setState(() => _startDate = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'تاريخ البداية', prefixIcon: Icon(Icons.date_range)),
            child: Text('${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes)),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _stepPreview() {
    return Column(
      children: [
        const Text('معاينة القسط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _previewRow('العميل', _selectedCustomer?.fullName ?? ''),
              const Divider(),
              _previewRow('عدد المنتجات', '${_cart.length}'),
              const Divider(),
              _previewRow('المبلغ الإجمالي', '$_totalPrice $_currency'),
              const Divider(),
              _previewRow('الدفعة الأولى', _downPaymentController.text.isEmpty ? '0' : '${_downPaymentController.text} $_currency'),
              const Divider(),
              _previewRow('مبلغ القسط', '${_installmentAmount.toStringAsFixed(0)} $_currency'),
              const Divider(),
              _previewRow('النظام', _frequency == 'daily' ? 'يومي' : _frequency == 'weekly' ? 'أسبوعي' : 'شهري'),
              const Divider(),
              _previewRow('تاريخ البداية', '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
            ],
          ),
        )),
      ],
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Tajawal'), textDirection: TextDirection.ltr)),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('السابق', style: TextStyle(fontFamily: 'Tajawal')))),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_step == 0 && _selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار عميل')));
                  return;
                }
                if (_step == 1 && _cart.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة منتج واحد على الأقل')));
                  return;
                }
                if (_step < 3) {
                  setState(() => _step++);
                } else {
                  _submit();
                }
              },
              child: Text(_step < 3 ? 'التالي' : 'إنشاء القسط', style: const TextStyle(fontFamily: 'Tajawal')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerPicker extends StatefulWidget {
  final ValueChanged<CustomerModel> onSelect;
  const _CustomerPicker({required this.onSelect});

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختيار عميل', style: TextStyle(fontFamily: 'Tajawal')),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'بحث', prefixIcon: Icon(Icons.search), labelStyle: TextStyle(fontFamily: 'Tajawal')),
              onChanged: (v) => context.read<CustomerBloc>().add(LoadCustomers(search: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoading) return const Center(child: CircularProgressIndicator());
                  if (state is CustomerLoaded && state.customers.isEmpty) return const Center(child: Text('لا يوجد عملاء', style: TextStyle(fontFamily: 'Tajawal')));
                  if (state is CustomerLoaded) {
                    return ListView(
                      children: state.customers.map((c) => ListTile(
                        title: Text(c.fullName, style: const TextStyle(fontFamily: 'Tajawal')),
                        subtitle: Text(c.phone ?? '', style: const TextStyle(fontFamily: 'Tajawal')),
                        onTap: () { widget.onSelect(c); Navigator.pop(context); },
                      )).toList(),
                    );
                  }
                  return const Center(child: Text('جاري التحميل...', style: TextStyle(fontFamily: 'Tajawal')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPicker extends StatefulWidget {
  final ValueChanged<ProductModel> onSelect;
  const _ProductPicker({required this.onSelect});

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختيار منتج', style: TextStyle(fontFamily: 'Tajawal')),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'بحث', prefixIcon: Icon(Icons.search), labelStyle: TextStyle(fontFamily: 'Tajawal')),
              onChanged: (v) => context.read<ProductBloc>().add(LoadProducts(search: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
                  if (state is ProductLoaded && state.products.isEmpty) return const Center(child: Text('لا يوجد منتجات', style: TextStyle(fontFamily: 'Tajawal')));
                  if (state is ProductLoaded) {
                    return ListView(
                      children: state.products.map((p) => ListTile(
                        title: Text(p.name, style: const TextStyle(fontFamily: 'Tajawal')),
                        subtitle: Text('${p.sellPriceInstallIqd ?? p.priceIqd ?? 0} IQD', style: const TextStyle(fontFamily: 'Tajawal')),
                        onTap: () { widget.onSelect(p); Navigator.pop(context); },
                      )).toList(),
                    );
                  }
                  return const Center(child: Text('جاري التحميل...', style: TextStyle(fontFamily: 'Tajawal')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
