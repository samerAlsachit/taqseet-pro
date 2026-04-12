import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/installment_model.dart';
import '../providers/installment_provider.dart';
import '../core/utils/formatter.dart';
import '../services/image_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Step management
  int _currentStep = 1;

  // Step 1: Customer selection
  final TextEditingController _customerSearchController =
      TextEditingController();
  String? _selectedCustomer;
  List<String> _filteredCustomers = [];

  // Step 2: Installment selection
  InstallmentModel? _selectedInstallment;

  // Step 3: Payment details
  final TextEditingController _amountController = TextEditingController();
  double _monthlyPayment = 0.0;

  // Image Service for digital receipts (replaces PDF)
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _loadCustomers() {
    final provider = Provider.of<InstallmentProvider>(context, listen: false);
    final customers = provider.installments
        .map((i) => i.customerName.trim())
        .toSet()
        .toList();
    setState(() {
      _filteredCustomers = customers;
    });
  }

  void _filterCustomers(String query) {
    final provider = Provider.of<InstallmentProvider>(context, listen: false);
    final allCustomers = provider.installments
        .map((i) => i.customerName.trim())
        .toSet()
        .toList();

    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = allCustomers;
      } else {
        _filteredCustomers = allCustomers
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  List<InstallmentModel> _getOpenInstallmentsForCustomer(String customerName) {
    final provider = Provider.of<InstallmentProvider>(context, listen: false);
    return provider.installments
        .where(
          (i) =>
              i.customerName.trim() == customerName &&
              i.status != 'completed' &&
              i.remainingAmount > 0,
        )
        .toList();
  }

  double _getCustomerTotalRemainingDebt(String customerName) {
    final provider = Provider.of<InstallmentProvider>(context, listen: false);
    return provider.installments
        .where(
          (i) =>
              i.customerName.trim() == customerName && i.status != 'completed',
        )
        .fold(0.0, (sum, i) => sum + i.remainingAmount);
  }

  void _selectCustomer(String customerName) {
    setState(() {
      _selectedCustomer = customerName;
      _customerSearchController.text = customerName;
      _currentStep = 2;
      _selectedInstallment = null;
    });
  }

  void _selectInstallment(InstallmentModel installment) {
    setState(() {
      _selectedInstallment = installment;
      _currentStep = 3;
      _amountController.clear();
      // Calculate monthly payment (approximate: total / 12 or remaining / remaining months)
      _monthlyPayment = installment.totalAmount / 12; // Default monthly
    });
  }

  void _fillOneInstallment() {
    HapticFeedback.lightImpact();
    setState(() {
      _amountController.text = _formatNumber(_monthlyPayment);
    });
  }

  void _fillTwoInstallments() {
    HapticFeedback.lightImpact();
    setState(() {
      _amountController.text = _formatNumber(_monthlyPayment * 2);
    });
  }

  void _fillFullAmount() {
    HapticFeedback.lightImpact();
    if (_selectedInstallment != null) {
      setState(() {
        _amountController.text = _formatNumber(
          _selectedInstallment!.remainingAmount,
        );
      });
    }
  }

  /// Generate receipt as image and share via WhatsApp
  Future<void> _generateAndShareReceipt(
    double paidAmount,
    double remainingAmount, {
    bool shareToWhatsApp = true,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate receipt number
      final receiptNumber =
          'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // Generate and share receipt as image
      await _imageService.generateAndShareReceipt(
        storeName: 'مرساة',
        customerName: _selectedCustomer!,
        customerPhone: null, // TODO: Add phone number support
        amountPaid: paidAmount,
        remainingBalance: remainingAmount,
        receiptNumber: receiptNumber,
        date: DateTime.now(),
        installmentId: _selectedInstallment?.id,
        phoneNumber: shareToWhatsApp ? null : null,
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تجهيز الوصل، جارٍ فتح المشاركة...',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر إنشاء الوصل: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Legacy text-based WhatsApp receipt (fallback)
  Future<void> _sendWhatsAppReceipt(
    double paidAmount,
    double remainingAmount,
  ) async {
    final message =
        '''وصل استلام من [محل مرساة]
السيد: $_selectedCustomer
تم استلام مبلغ: ${_formatNumber(paidAmount)} ${CurrencyFormatter.currencySymbol}
المتبقي بذمتكم: ${_formatNumber(remainingAmount)} ${CurrencyFormatter.currencySymbol}
شكراً لالتزامكم.''';

    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح WhatsApp',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatNumber(double value) {
    return CurrencyFormatter.formatCurrency(
      value,
    ).replaceAll(' ${CurrencyFormatter.currencySymbol}', '');
  }

  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }

  Future<void> _confirmPayment() async {
    if (_selectedInstallment == null || _amountController.text.isEmpty) return;

    final amount = _parseAmount(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال مبلغ صحيح',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<InstallmentProvider>(context, listen: false);

    // Calculate new values
    final newPaidAmount = _selectedInstallment!.paidAmount + amount;
    final newRemainingAmount =
        _selectedInstallment!.totalAmount - newPaidAmount;
    final newStatus = newRemainingAmount <= 0
        ? 'completed'
        : _selectedInstallment!.status;

    // Create updated installment
    final updatedInstallment = _selectedInstallment!.copyWith(
      paidAmount: newPaidAmount,
      remainingAmount: newRemainingAmount > 0 ? newRemainingAmount : 0,
      status: newStatus,
    );

    // Update in provider
    await provider.updateInstallment(updatedInstallment);

    // Show success and ask about receipt
    if (mounted) {
      _showReceiptDialog(
        amount,
        newRemainingAmount > 0 ? newRemainingAmount : 0,
      );
    }
  }

  /// Show dialog asking if merchant wants to send receipt
  void _showReceiptDialog(double paidAmount, double remainingAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle2,
                color: Color(0xFF27AE60),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم التسديد بنجاح!',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A192F),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم استلام ${_formatNumber(paidAmount)} ${CurrencyFormatter.currencySymbol} من $_selectedCustomer',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'المتبقي الحالي للقسط: ${_formatNumber(remainingAmount)} ${CurrencyFormatter.currencySymbol}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A192F),
              ),
            ),
            const SizedBox(height: 24),
            // Receipt Options
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'هل تريد إرسال وصل استلام للزبون؟',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A192F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Generate Receipt Image and Share
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        await _generateAndShareReceipt(
                          paidAmount,
                          remainingAmount,
                          shareToWhatsApp: true,
                        );
                        Navigator.pop(context, true); // Return to dashboard
                      },
                      icon: const Icon(LucideIcons.share2, size: 18),
                      label: const Text(
                        'نعم، إرسال الوصل',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // WhatsApp Quick Message
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendWhatsAppReceipt(paidAmount, remainingAmount);
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(
                        LucideIcons.messageCircle,
                        color: Color(0xFF25D366),
                        size: 18,
                      ),
                      label: const Text(
                        'رسالة نصية WhatsApp',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: Color(0xFF25D366),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25D366)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Skip button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to dashboard
              },
              child: const Text(
                'لا، العودة للرئيسية',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        title: const Text(
          'تسديد دفعة',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Steps
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // Step 1: Customer Selection
              _buildStep1(),

              // Step 2: Installment Selection
              if (_currentStep >= 2) _buildStep2(),

              // Step 3: Payment Details
              if (_currentStep >= 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepCircle(1, 'العميل'),
          _buildStepLine(_currentStep > 1),
          _buildStepCircle(2, 'القسط'),
          _buildStepLine(_currentStep > 2),
          _buildStepCircle(3, 'الدفع'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF0A192F) : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: const Color(0xFF27AE60), width: 3)
                  : null,
            ),
            child: Center(
              child: isActive && _currentStep > step
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF0A192F) : Colors.grey,
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? const Color(0xFF0A192F) : Colors.grey.shade200,
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختيار العميل',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            color: Color(0xFF0A192F),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _customerSearchController,
            onChanged: _filterCustomers,
            decoration: InputDecoration(
              hintText: 'ابحث عن العميل بالاسم...',
              hintStyle: const TextStyle(
                fontFamily: 'Tajawal',
                color: Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: Color(0xFF64748B),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
        const SizedBox(height: 12),
        if (_customerSearchController.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return ListTile(
                  leading: const Icon(
                    LucideIcons.user,
                    color: Color(0xFF64748B),
                  ),
                  title: Text(
                    customer,
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                  onTap: () => _selectCustomer(customer),
                  trailing: const Icon(LucideIcons.chevronLeft, size: 18),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStep2() {
    final openInstallments = _selectedCustomer != null
        ? _getOpenInstallmentsForCustomer(_selectedCustomer!)
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'اختيار القسط',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Color(0xFF0A192F),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                  _selectedCustomer = null;
                  _customerSearchController.clear();
                });
              },
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: const Text(
                'تغيير العميل',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
              ),
            ),
          ],
        ),
        if (_selectedCustomer != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0A192F).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.user,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'العميل: $_selectedCustomer',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.wallet,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'إجمالي الديون المتبقية: ${CurrencyFormatter.formatCurrency(_getCustomerTotalRemainingDebt(_selectedCustomer!))}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (openInstallments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'لا يوجد أقساط مفتوحة لهذا العميل',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: openInstallments.length,
            itemBuilder: (context, index) {
              final installment = openInstallments[index];
              final isSelected = _selectedInstallment?.id == installment.id;

              return GestureDetector(
                onTap: () => _selectInstallment(installment),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF27AE60)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.smartphone,
                                color: isSelected
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFF0A192F),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'منتج #${installment.id}',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF27AE60)
                                      : const Color(0xFF0A192F),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: installment.statusColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              installment.statusDisplay,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: installment.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'تاريخ الاستحقاق: ${installment.formattedDueDate}',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'المبلغ الكلي',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatCurrency(
                                  installment.totalAmount,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'المبلغ المتبقي',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatCurrency(
                                  installment.remainingAmount,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تفاصيل الدفع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Color(0xFF0A192F),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 2;
                  _selectedInstallment = null;
                  _amountController.clear();
                });
              },
              icon: const Icon(LucideIcons.arrowRight, size: 16),
              label: const Text(
                'تغيير القسط',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
              ),
            ),
          ],
        ),
        if (_selectedInstallment != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.creditCard,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  'القسط المختار: #${_selectedInstallment!.id} - متبقي: ${CurrencyFormatter.formatCurrency(_selectedInstallment!.remainingAmount)}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Quick fill buttons - 3 buttons row
        Row(
          children: [
            // 1 Installment
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _fillOneInstallment,
                icon: const Icon(LucideIcons.calendar, size: 14),
                label: const Text(
                  'قسط واحد',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 2 Installments
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _fillTwoInstallments,
                icon: const Icon(LucideIcons.calendarDays, size: 14),
                label: const Text(
                  'قسطين',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A192F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Full Amount
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _fillFullAmount,
                icon: const Icon(LucideIcons.checkCircle, size: 14),
                label: const Text(
                  'تصفية',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Amount input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              hintText: 'أدخل المبلغ يدوياً (سداد جزئي)...',
              hintStyle: const TextStyle(
                fontFamily: 'Tajawal',
                color: Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(
                LucideIcons.banknote,
                color: Color(0xFF64748B),
              ),
              suffixText: CurrencyFormatter.currencySymbol,
              suffixStyle: const TextStyle(
                fontFamily: 'Tajawal',
                color: Color(0xFF64748B),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _confirmPayment,
            icon: const Icon(LucideIcons.check),
            label: const Text(
              'تأكيد عملية التسديد',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
