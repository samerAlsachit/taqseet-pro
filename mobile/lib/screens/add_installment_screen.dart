import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';
import '../services/thabit_local_db_service.dart';
import '../services/product_service.dart';
import '../services/installment_service.dart';
import '../controllers/products_controller.dart';
import '../providers/installment_provider.dart';
import 'add_customer_screen.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class AddInstallmentScreen extends StatefulWidget {
  const AddInstallmentScreen({super.key});
  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ThabitLocalDBService _localDB = ThabitLocalDBService();

  List<CustomerModel> customers = [];
  List<ProductModel> products = [];
  bool _isLoading = true;

  CustomerModel? _selectedCustomer;
  final List<CartItem> _cart = [];

  final _installmentAmountController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  String _frequency = 'monthly';

  static const Color _navyDark = Color(0xFF0A192F);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _localDB.init();
      final customerMaps = _localDB.getAllCustomers();
      customers = customerMaps.map((map) => CustomerModel.fromJson(map)).toList();

      final productService = ProductService();
      final productController = ProductsController();
      await productService.syncProducts();
      products = productController.getAllProducts();
    } catch (e) {
      debugPrint('Error loading data: $e');
      try {
        final productController = ProductsController();
        products = productController.getAllProducts();
      } catch (_) {
        products = [];
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _totalAmount {
    return _cart.fold(0.0, (sum, item) {
      return sum + (item.product.sellPriceInstallIqd * item.quantity);
    });
  }

  int get _numberOfPayments {
    final installmentAmount = double.tryParse(_installmentAmountController.text) ?? 0;
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0;
    final remaining = _totalAmount - downPayment;
    if (installmentAmount > 0 && remaining > 0) {
      return (remaining / installmentAmount).ceil();
    }
    return 0;
  }

  String _formatNumber(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _addToCart(ProductModel product) {
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'المنتج غير متوفر في المخزن',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      if (_cart[existingIndex].quantity < product.stockQuantity) {
        setState(() {
          _cart[existingIndex].quantity++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'الكمية المطلوبة غير متوفرة',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() {
        _cart.add(CartItem(product: product));
      });
    }
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _updateCartQuantity(int index, int delta) {
    final item = _cart[index];
    final newQuantity = item.quantity + delta;

    if (newQuantity > 0 && newQuantity <= item.product.stockQuantity) {
      setState(() {
        item.quantity = newQuantity;
      });
    } else if (newQuantity > item.product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الكمية المطلوبة غير متوفرة في المخزن',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// حساب تاريخ الانتهاء
  DateTime _calculateEndDate() {
    final numberOfPayments = _numberOfPayments;
    if (numberOfPayments <= 0) return _startDate;

    switch (_frequency) {
      case 'daily':
        return _startDate.add(Duration(days: numberOfPayments - 1));
      case 'weekly':
        return _startDate.add(Duration(days: (numberOfPayments - 1) * 7));
      case 'monthly':
      default:
        return DateTime(
          _startDate.year,
          _startDate.month + numberOfPayments - 1,
          _startDate.day,
        );
    }
  }

  /// عرض نصي للتكرار
  String get _frequencyDisplay {
    switch (_frequency) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
      default:
        return 'شهري';
    }
  }

  void _showConfirmationDialog() {
    // صمام أمان - التحقق من وجود بيانات صحيحة
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار العميل أولاً',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إضافة منتجات للسلة أولاً',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final endDate = _calculateEndDate();
    const currency = 'د.ع';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'تأكيد إضافة القسط',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A192F),
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmItem('العميل:', _selectedCustomer?.name ?? 'غير محدد'),
              const Divider(height: 24),
              ..._cart.map(
                (item) => _buildConfirmItem(
                  '${item.product.name.isNotEmpty ? item.product.name : "منتج"} (×${item.quantity}):',
                  '${_formatNumber(item.product.sellPriceInstallIqd * item.quantity)} $currency',
                ),
              ),
              const Divider(height: 24),
              _buildConfirmItem(
                'الإجمالي:',
                '${_formatNumber(_totalAmount)} $currency',
              ),
              _buildConfirmItem(
                'الدفعة المقدمة:',
                '${_formatNumber(double.tryParse(_downPaymentController.text) ?? 0)} $currency',
              ),
              _buildConfirmItem(
                'مبلغ القسط:',
                '${_formatNumber(double.tryParse(_installmentAmountController.text) ?? 0)} $currency',
              ),
              _buildConfirmItem(
                'عدد الدفعات:',
                '$_numberOfPayments دفعة ($_frequencyDisplay)',
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A192F).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مبلغ القسط:',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A192F),
                      ),
                    ),
                    Text(
                      '${_formatNumber(double.tryParse(_installmentAmountController.text) ?? 0)} $currency',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF0A192F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildConfirmItem(
                'تاريخ الانتهاء:',
                intl.DateFormat('yyyy/MM/dd').format(endDate),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveInstallment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A192F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تأكيد الحفظ',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A192F),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// حفظ القسط - النسخة المحسنة
  Future<void> _saveInstallment() async {
    // ===== VALIDATION =====
    if (_selectedCustomer == null) {
      _showError('يرجى اختيار العميل');
      return;
    }

    if (_cart.isEmpty) {
      _showError('يرجى إضافة منتج للسلة');
      return;
    }

    final installmentAmount = double.tryParse(_installmentAmountController.text) ?? 0;
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0;
    final totalPrice = _totalAmount;

    if (totalPrice <= 0) {
      _showError('الإجمالي يجب أن يكون أكبر من صفر');
      return;
    }

    if (installmentAmount <= 0) {
      _showError('يرجى إدخال مبلغ القسط الشهري');
      return;
    }

    if (installmentAmount >= (totalPrice - downPayment)) {
      _showError('مبلغ القسط يجب أن يكون أقل من المتبقي');
      return;
    }

    // ===== PREPARE DATA =====
    // المنتجات: استخدام سعر التقسيط IQD فقط (حسب طلب سامر)
    final products = _cart.map((item) => {
      'product_id': item.product.id.toString(),
      'quantity': item.quantity,
      'price': item.product.sellPriceInstallIqd.toDouble(),
    }).toList();

    debugPrint('═══════════════════════════════════════════');
    debugPrint('� SAVING INSTALLMENT');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('👤 Customer: ${_selectedCustomer?.name} (${_selectedCustomer?.id})');
    debugPrint('🛒 Products: ${products.length}');
    debugPrint('💰 Total: $totalPrice, Down: $downPayment, Installment: $installmentAmount');
    debugPrint('📅 Frequency: $_frequency, Start: ${_startDate.toIso8601String()}');
    debugPrint('═══════════════════════════════════════════\n');

    setState(() => _isLoading = true);

    try {
      final service = InstallmentService();
      final result = await service.createInstallment(
        customerId: _selectedCustomer!.id.toString(),
        products: products,
        totalPrice: totalPrice,
        downPayment: downPayment,
        installmentAmount: installmentAmount,
        frequency: _frequency,
        startDate: _startDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (result['success'] == true) {
        // تحديث المخزن محلياً
        for (final item in _cart) {
          item.product.stockQuantity -= item.quantity;
        }

        // تحديث قائمة الأقساط
        if (mounted) {
          context.read<InstallmentProvider>().loadInstallments();
        }

        _showSuccess(result['message'] ?? 'تم إنشاء القسط بنجاح!');

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _showError(result['message'] ?? 'فشل إنشاء القسط');
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: _navyDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// اختيار تاريخ بدء القسط
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _navyDark,
              onPrimary: Colors.white,
              onSurface: _navyDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _showProductSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'اختيار المنتجات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A192F),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isInCart = _cart.any(
                        (item) => item.product.id == product.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0A192F,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.package,
                              color: Color(0xFF0A192F),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المخزن: ${product.quantity}',
                                style: const TextStyle(fontFamily: 'Tajawal'),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  // Show INSTALLMENT prices (not cash prices)
                                  if (product.sellPriceInstallIqd > 0)
                                    Text(
                                      '${_formatNumber(product.sellPriceInstallIqd)} د.ع',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A192F),
                                      ),
                                    ),
                                  if (product.sellPriceInstallIqd > 0 &&
                                      product.sellPriceInstallUsd > 0)
                                    const Text(
                                      ' | ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  if (product.sellPriceInstallUsd > 0)
                                    Text(
                                      '\$${_formatNumber(product.sellPriceInstallUsd)}',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: product.quantity > 0
                                ? () {
                                    _addToCart(product);
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0A192F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isInCart ? 'إضافة +' : 'اختيار',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        title: const Text(
          'إضافة قسط جديد',
          style: TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A192F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCurrencyButton('د.ع', true),
                  _buildCurrencyButton('\$', false),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerDropdown(),
              const SizedBox(height: 24),
              _buildCartSection(),
              const SizedBox(height: 24),
              _buildAddProductButton(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'الدفعة المقدمة',
                      controller: _downPaymentController,
                      icon: LucideIcons.wallet,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffixText: 'د.ع',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      label: 'مبلغ القسط',
                      controller: _installmentAmountController,
                      icon: LucideIcons.wallet,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      suffixText: 'د.ع',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFrequencySelector(),
              const SizedBox(height: 20),
              _buildDatePickerField(),
              const SizedBox(height: 32),
              _buildCalculationSummary(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// زر العملة (ملغى - نستخدم الدينار فقط)
  Widget _buildCurrencyButton(String label, bool isIQD) {
    return const SizedBox.shrink();
  }

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'اختيار العميل',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerScreen(),
                  ),
                );
                if (result != null && result is CustomerModel) {
                  setState(() {
                    customers.add(result);
                    _selectedCustomer = result;
                  });
                }
              },
              icon: const Icon(
                LucideIcons.userPlus,
                size: 16,
                color: Color(0xFF1976D2),
              ),
              label: const Text(
                'عميل جديد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'جاري تحميل البيانات...',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else if (customers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.userX,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لا يوجد عملاء. أضف عميلاً أولاً.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CustomerModel>(
                isExpanded: true,
                value: _selectedCustomer,
                hint: const Text(
                  'اختر عميلاً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF94A3B8),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.chevronDown,
                  color: Color(0xFF64748B),
                ),
                items: customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text(
                      customer.fullName,
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCustomer = value),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCartSection() {
    if (_cart.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.shoppingCart,
                color: Color(0xFF94A3B8),
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'السلة فارغة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    const currency = 'د.ع';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0A192F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المنتجات المختارة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'الإجمالي: ${_formatNumber(_totalAmount)} $currency',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cart.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _cart[index];
              final price = item.product.sellPriceInstallIqd;
              final total = price * item.quantity;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  item.product.name.isNotEmpty ? item.product.name : 'منتج',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.minus, size: 14),
                              onPressed: () => _updateCartQuantity(index, -1),
                              color: const Color(0xFF0A192F),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.plus, size: 14),
                              onPressed: () => _updateCartQuantity(index, 1),
                              color: const Color(0xFF0A192F),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatNumber(item.product.sellPriceInstallIqd)} د.ع',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A192F),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المجموع: ${_formatNumber(total)} د.ع',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeFromCart(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showProductSelector,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'إضافة منتج للسلة',
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A192F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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

  Widget _buildFrequencySelector() {
    final frequencies = [
      {'value': 'monthly', 'label': 'شهري', 'icon': LucideIcons.calendar},
      {'value': 'weekly', 'label': 'أسبوعي', 'icon': LucideIcons.calendarDays},
      {'value': 'daily', 'label': 'يومي', 'icon': LucideIcons.clock},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نظام الدفع',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: frequencies.map((freq) {
              final isSelected = _frequency == freq['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => _frequency = freq['value'] as String,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0A192F)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          freq['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          freq['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تاريخ أول قسط',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  color: Color(0xFF0A192F),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  intl.DateFormat('yyyy/MM/dd').format(_startDate),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF0A192F),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronDown,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationSummary() {
    const currency = 'د.ع';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A192F).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(LucideIcons.calculator, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'الحساب التلقائي',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'مبلغ القسط:',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatNumber(double.tryParse(_installmentAmountController.text) ?? 0)} $currency',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Tajawal',
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_numberOfPayments > 0)
            Text(
              '($_numberOfPayments دفعة $_frequencyDisplay)',
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Tajawal',
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_formKey.currentState!.validate() &&
              _selectedCustomer != null &&
              _cart.isNotEmpty) {
            _showConfirmationDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'يرجى اختيار عميل وإضافة منتجات للسلة',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(LucideIcons.check, color: Colors.white),
        label: const Text(
          'معاينة وحفظ',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A192F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
