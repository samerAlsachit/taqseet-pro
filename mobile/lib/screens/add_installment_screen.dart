import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' as intl;
import '../models/customer_model.dart';
import '../models/product_model.dart';
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

  // Mock data - in real app, these come from providers/database
  List<CustomerModel> customers = [];
  List<ProductModel> products = [];

  CustomerModel? _selectedCustomer;
  final List<CartItem> _cart = [];
  bool _isIQD = true; // Currency toggle: true = IQD, false = USD

  final _monthsController = TextEditingController();
  final _downPaymentController = TextEditingController();
  DateTime _firstPaymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    customers = [
      CustomerModel(
        id: '1',
        fullName: 'أحمد محمد',
        phone: '07701234567',
        nationalId: '12345678901',
        address: 'بغداد',
      ),
      CustomerModel(
        id: '2',
        fullName: 'علي حسين',
        phone: '07709876543',
        nationalId: '12345678902',
        address: 'البصرة',
      ),
    ];

    products = [
      ProductModel(
        id: '1',
        name: 'موبايل سامسونج',
        stockQuantity: 10,
        priceIQD: 750000,
        priceUSD: 575,
      ),
      ProductModel(
        id: '2',
        name: 'لابتوب ديل',
        stockQuantity: 5,
        priceIQD: 1200000,
        priceUSD: 920,
      ),
      ProductModel(
        id: '3',
        name: 'سماعات بلوتوث',
        stockQuantity: 20,
        priceIQD: 125000,
        priceUSD: 96,
      ),
    ];
  }

  double get _totalAmount {
    return _cart.fold(0, (sum, item) {
      final price = _isIQD ? item.product.priceIQD : item.product.priceUSD;
      return sum + (price * item.quantity);
    });
  }

  double get _monthlyInstallment {
    final months = int.tryParse(_monthsController.text) ?? 0;
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0;
    if (months > 0) {
      return (_totalAmount - downPayment) / months;
    }
    return 0;
  }

  String _formatNumber(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
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

  DateTime _calculateEndDate() {
    final months = int.tryParse(_monthsController.text) ?? 0;
    return DateTime(
      _firstPaymentDate.year,
      _firstPaymentDate.month + months,
      _firstPaymentDate.day,
    );
  }

  void _showConfirmationDialog() {
    final endDate = _calculateEndDate();
    final currency = _isIQD ? 'د.ع' : '\$';

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
              _buildConfirmItem('العميل:', _selectedCustomer?.name ?? ''),
              const Divider(height: 24),
              ..._cart.map(
                (item) => _buildConfirmItem(
                  '${item.product.name} (×${item.quantity}):',
                  '${_formatNumber(_isIQD ? item.product.priceIQD * item.quantity : item.product.priceUSD * item.quantity)} $currency',
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
              _buildConfirmItem('عدد الأشهر:', '${_monthsController.text} شهر'),
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
                      'القسط الشهري:',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A192F),
                      ),
                    ),
                    Text(
                      '${_formatNumber(_monthlyInstallment)} $currency',
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

  void _saveInstallment() {
    // Deduct from inventory
    for (final cartItem in _cart) {
      cartItem.product.stockQuantity -= cartItem.quantity;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم حفظ القسط وتحديث المخزن بنجاح!',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: const Color(0xFF0A192F),
        action: SnackBarAction(
          label: 'تراجع',
          textColor: Colors.white,
          onPressed: () {
            for (final cartItem in _cart) {
              cartItem.product.stockQuantity += cartItem.quantity;
            }
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstPaymentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A192F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0A192F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _firstPaymentDate = picked;
      });
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
                          subtitle: Text(
                            'المخزن: ${product.stockQuantity} | ${_isIQD ? "${_formatNumber(product.priceIQD)} د.ع" : "${_formatNumber(product.priceUSD)} \$"}',
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                          trailing: ElevatedButton(
                            onPressed: product.stockQuantity > 0
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
                      suffixText: _isIQD ? 'د.ع' : '\$',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      label: 'عدد الأشهر',
                      controller: _monthsController,
                      icon: LucideIcons.calendarDays,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
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

  Widget _buildCurrencyButton(String label, bool isIQD) {
    final isSelected = _isIQD == isIQD;
    return GestureDetector(
      onTap: () => setState(() => _isIQD = isIQD),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A192F) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: isSelected ? Colors.white : const Color(0xFF0A192F),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
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
                    customer.name,
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

    final currency = _isIQD ? 'د.ع' : '\$';

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
              final price = _isIQD
                  ? item.product.priceIQD
                  : item.product.priceUSD;
              final total = price * item.quantity;

              return ListTile(
                title: Text(
                  item.product.name,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${_formatNumber(price)} $currency × ${item.quantity}',
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatNumber(total)} $currency',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A192F),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.minus, size: 16),
                            onPressed: () => _updateCartQuantity(index, -1),
                            color: const Color(0xFF0A192F),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.plus, size: 16),
                            onPressed: () => _updateCartQuantity(index, 1),
                            color: const Color(0xFF0A192F),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeFromCart(index),
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
        icon: const Icon(LucideIcons.plus, color: Color(0xFF0A192F)),
        label: const Text(
          'إضافة منتج للسلة',
          style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF0A192F)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0A192F),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF0A192F)),
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
                  intl.DateFormat('yyyy/MM/dd').format(_firstPaymentDate),
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
    final currency = _isIQD ? 'د.ع' : '\$';

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
            'قيمة القسط الشهري:',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Tajawal',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatNumber(_monthlyInstallment)} $currency',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Tajawal',
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_monthsController.text.isNotEmpty)
            Text(
              '(${_monthsController.text} دفعة شهرية)',
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
