import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/installment.dart';
import '../../data/models/payment_schedule.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../presentation/providers/installment_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class AddInstallmentScreen extends StatefulWidget {
  const AddInstallmentScreen({super.key});

  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _downPaymentController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<PaymentSchedule> _schedule = [];

  Customer? _selectedCustomer;
  Product? _selectedProduct;
  String _selectedFrequency = 'monthly';
  DateTime _startDate = DateTime.now();

  bool _isLoadingCustomers = false;
  bool _isLoadingProducts = false;
  bool _isCalculating = false;
  bool _isSaving = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  int get _totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + (item['total'] as int));

  int get _downPayment => int.tryParse(_downPaymentController.text) ?? 0;

  int get _installmentAmount =>
      int.tryParse(_installmentAmountController.text) ?? 0;

  int get _financedAmount => _totalPrice - _downPayment;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _downPaymentController.dispose();
    _installmentAmountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await Future.wait([_loadCustomers(), _loadProducts()]);
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final db = DatabaseHelper();
      final repo = CustomerRepository(db);
      final customers = await repo.getCustomers();
      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() => _isLoadingCustomers = false);
      _showError('خطأ في تحميل العملاء: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final db = DatabaseHelper();
      final repo = ProductRepository(db);
      final products = await repo.getAll();
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => _isLoadingProducts = false);
      _showError('خطأ في تحميل المنتجات: $e');
    }
  }

  // ─── Cart ─────────────────────────────────────────────────────────────────

  void _addToCart(Product product) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final existingIndex = _cartItems.indexWhere(
      (item) => item['product'].id == product.id,
    );

    setState(() {
      if (existingIndex != -1) {
        _cartItems[existingIndex]['quantity'] += quantity;
        _cartItems[existingIndex]['total'] =
            (_cartItems[existingIndex]['product'] as Product)
                .sellPriceInstallIqd *
            _cartItems[existingIndex]['quantity'];
      } else {
        _cartItems.add({
          'product': product,
          'quantity': quantity,
          'total': product.sellPriceInstallIqd * quantity,
        });
      }
      _selectedProduct = null;
      _quantityController.text = '1';
      // مسح الجدول القديم عند تغيير السلة
      _schedule = [];
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _schedule = [];
    });
  }

  void _updateQuantity(int index, int quantity) {
    if (quantity <= 0) return;
    setState(() {
      final item = _cartItems[index];
      item['quantity'] = quantity;
      item['total'] =
          (item['product'] as Product).sellPriceInstallIqd * quantity;
      _schedule = [];
    });
  }

  // ─── Calculate (يُستدعى فقط عند الضغط على الزر) ──────────────────────────

  Future<void> _calculateInstallments() async {
    // التحقق من المدخلات أولاً
    if (_cartItems.isEmpty) {
      _showError('يرجى إضافة منتج أولاً');
      return;
    }
    if (_installmentAmount <= 0) {
      _showError('يرجى إدخال مبلغ القسط');
      return;
    }
    if (_financedAmount <= 0) {
      _showError('المبلغ الممول يجب أن يكون أكبر من صفر');
      return;
    }

    setState(() => _isCalculating = true);

    // نفّذ الحساب خارج الـ UI thread
    await Future.microtask(() {
      try {
        final schedule = <PaymentSchedule>[];
        final count = (_financedAmount / _installmentAmount).ceil();
        final remainder = _financedAmount % _installmentAmount;
        DateTime currentDate = _startDate;

        for (int i = 1; i <= count; i++) {
          final amount = (i == count && remainder > 0)
              ? remainder
              : _installmentAmount;

          schedule.add(
            PaymentSchedule(
              id: '',
              planId: '',
              storeId: 'default_store',
              installmentNo: i,
              dueDate: currentDate,
              amount: amount,
              status: 'pending',
            ),
          );

          currentDate = _nextDate(currentDate);
        }

        if (mounted) setState(() => _schedule = schedule);
      } catch (e) {
        _showError('خطأ في الحساب: $e');
      }
    });

    if (mounted) setState(() => _isCalculating = false);
  }

  DateTime _nextDate(DateTime date) {
    switch (_selectedFrequency) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
      default:
        return DateTime(date.year, date.month + 1, date.day);
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveInstallment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('يرجى اختيار العميل');
      return;
    }
    if (_cartItems.isEmpty) {
      _showError('يرجى إضافة منتج واحد على الأقل');
      return;
    }
    if (_schedule.isEmpty) {
      _showError('يرجى حساب جدول الأقساط أولاً');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final productNames = _cartItems
          .map((i) => '${(i['product'] as Product).name} x${i['quantity']}')
          .join(', ');

      final installment = Installment(
        storeId: 'default_store',
        customerId: _selectedCustomer!.id!,
        productId: (_cartItems.first['product'] as Product).id!,
        productName: productNames,
        totalPrice: _totalPrice,
        downPayment: _downPayment,
        financedAmount: _financedAmount,
        remainingAmount: _financedAmount,
        currency: 'IQD',
        frequency: _selectedFrequency,
        installmentAmount: _installmentAmount,
        installmentsCount: _schedule.length,
        startDate: _startDate,
        endDate: _schedule.last.dueDate,
        status: 'active',
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<InstallmentProvider>(context, listen: false);
      await provider.addInstallment(installment: installment);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حفظ القسط بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('خطأ في الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة قسط جديد'),
        backgroundColor: AppColors.electric,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerSection(),
              const SizedBox(height: 24),
              _buildProductsSection(),
              const SizedBox(height: 24),
              if (_cartItems.isNotEmpty) ...[
                _buildCartSection(),
                const SizedBox(height: 24),
                _buildPaymentDetailsSection(),
                const SizedBox(height: 24),
              ],
              if (_schedule.isNotEmpty) ...[
                _buildScheduleSection(),
                const SizedBox(height: 24),
              ],
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sections ─────────────────────────────────────────────────────────────

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختيار العميل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingCustomers)
              const Center(child: CircularProgressIndicator())
            else if (_customers.isEmpty)
              const Text('لا يوجد عملاء')
            else
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'العميل',
                  border: OutlineInputBorder(),
                ),
                items: _customers
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c, child: Text(c.fullName)),
                    )
                    .toList(),
                onChanged: (c) => setState(() => _selectedCustomer = c),
                validator: (v) => v == null ? 'يرجى اختيار العميل' : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختيار المنتجات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingProducts)
              const Center(child: CircularProgressIndicator())
            else if (_products.isEmpty)
              const Text('لا توجد منتجات')
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'المنتج',
                        border: OutlineInputBorder(),
                      ),
                      items: _products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.name} - ${p.sellPriceInstallIqd} IQD',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (p) {
                        if (p != null) _addToCart(p);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سلة المشتريات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                final product = item['product'] as Product;
                final quantity = item['quantity'] as int;
                final total = item['total'] as int;

                return ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.sellPriceInstallIqd} IQD × $quantity = $total IQD',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _updateQuantity(index, quantity - 1),
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _updateQuantity(index, quantity + 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () => _removeFromCart(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع الكلي:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$_totalPrice IQD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electric,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل الدفع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // الدفعة المقدمة + مبلغ القسط
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _downPaymentController,
                    decoration: const InputDecoration(
                      labelText: 'الدفعة المقدمة (اختياري)',
                      border: OutlineInputBorder(),
                      prefixText: 'IQD ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    // ← لا يوجد onChanged هنا
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _installmentAmountController,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ القسط',
                      border: OutlineInputBorder(),
                      prefixText: 'IQD ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال مبلغ القسط';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'يرجى إدخال مبلغ صحيح';
                      }
                      return null;
                    },
                    // ← لا يوجد onChanged هنا
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // نظام الدفع + تاريخ البدء
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'نظام الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('يومي')),
                      DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                      DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value!;
                        _schedule = []; // مسح الجدول عند تغيير النظام
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                          _schedule = []; // مسح الجدول عند تغيير التاريخ
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ البدء',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startDate.toString().split(' ')[0]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ملخص المبالغ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.electric.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _summaryRow('المجموع الكلي:', '$_totalPrice IQD'),
                  const SizedBox(height: 8),
                  _summaryRow('الدفعة المقدمة:', '$_downPayment IQD'),
                  const SizedBox(height: 8),
                  _summaryRow('المبلغ الممول:', '$_financedAmount IQD'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── زر احسب الجدول ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCalculating ? null : _calculateInstallments,
                icon: _isCalculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: Text(
                  _isCalculating ? 'جاري الحساب...' : 'احسب جدول الأقساط',
                  style: const TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.electric,
                  side: const BorderSide(color: AppColors.electric),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'جدول الأقساط',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_schedule.length} قسط',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schedule.length,
              itemBuilder: (context, index) {
                final payment = _schedule[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.electric,
                    child: Text(
                      '${payment.installmentNo}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('القسط ${payment.installmentNo}'),
                  subtitle: Text(payment.dueDate.toString().split(' ')[0]),
                  trailing: Text(
                    '${payment.amount} IQD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.electric,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveInstallment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electric,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('حفظ القسط', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
