import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style:
                    const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                decoration: const InputDecoration(
                  hintText: 'البحث في العملاء...',
                  hintStyle:
                      TextStyle(color: Colors.white70, fontFamily: 'Tajawal'),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<CustomerProvider>().search(value);
                },
              )
            : const Text(
                'العملاء',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  context.read<CustomerProvider>().clearSearch();
                } else {
                  _isSearching = true;
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.white),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.customers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            );
          }

          if (provider.error != null && provider.customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(
                        fontFamily: 'Tajawal', color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadCustomers(),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(fontFamily: 'Tajawal')),
                  ),
                ],
              ),
            );
          }

          if (provider.customers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد عملاء',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أضف عميلاً جديداً للبدء',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCustomers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.customers.length,
              itemBuilder: (context, index) {
                final customer = provider.customers[index];
                return _CustomerCard(customer: customer);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          );
        },
        backgroundColor: AppColors.electric,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'إضافة عميل',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showCustomerDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.electric.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: customer.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            customer.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppColors.electric,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.electric,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            customer.phone ?? 'لا يوجد رقم',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (customer.idNumber != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.badge,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Text(
                              customer.idNumber!,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCustomer(context);
                    } else if (value == 'delete') {
                      _deleteCustomer(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.electric, size: 20),
                          const SizedBox(width: 8),
                          const Text('تعديل',
                              style: TextStyle(fontFamily: 'Tajawal')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          const Text('حذف',
                              style: TextStyle(fontFamily: 'Tajawal')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => _CustomerDetailsSheet(
          customer: customer,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _editCustomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    );
  }

  void _deleteCustomer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Tajawal')),
        content: Text(
          'هل أنت متأكد من حذف العميل "${customer.fullName}"؟',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<CustomerProvider>();
              final success = await provider.deleteCustomer(customer.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم حذف العميل',
                          style: TextStyle(fontFamily: 'Tajawal'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CustomerDetailsSheet extends StatefulWidget {
  final CustomerModel customer;
  final ScrollController scrollController;

  const _CustomerDetailsSheet({
    required this.customer,
    required this.scrollController,
  });

  @override
  State<_CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<_CustomerDetailsSheet> {
  @override
  void initState() {
    super.initState();
    // Fetch customer details with installments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomerDetails(widget.customer.id);
    });
  }

  @override
  void dispose() {
    context.read<CustomerProvider>().clearCustomerDetails();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final details = provider.customerDetails;
        final plans = provider.installmentPlans;
        final summary = provider.installmentSummary;

        // Use fetched details or fallback to passed customer
        final displayCustomer =
            details != null ? CustomerModel.fromJson(details) : widget.customer;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: widget.scrollController,
            children: [
              // Handle
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

              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.navy.withOpacity(0.1),
                  backgroundImage: displayCustomer.avatarUrl != null
                      ? NetworkImage(displayCustomer.avatarUrl!)
                      : null,
                  child: displayCustomer.avatarUrl == null
                      ? const Icon(Icons.person,
                          color: AppColors.navy, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Center(
                child: Text(
                  displayCustomer.fullName,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info Cards
              _InfoCard(
                icon: Icons.phone,
                title: 'رقم الهاتف',
                value: displayCustomer.phone ?? 'غير متوفر',
              ),
              _InfoCard(
                icon: Icons.badge,
                title: 'رقم الهوية',
                value: displayCustomer.idNumber ?? 'غير متوفر',
              ),
              _InfoCard(
                icon: Icons.location_on,
                title: 'العنوان',
                value: displayCustomer.address ?? 'غير متوفر',
              ),
              if (displayCustomer.createdAt != null)
                _InfoCard(
                  icon: Icons.calendar_today,
                  title: 'تاريخ الإضافة',
                  value:
                      '${displayCustomer.createdAt!.day}/${displayCustomer.createdAt!.month}/${displayCustomer.createdAt!.year}',
                ),

              // Installment Summary
              if (summary != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('ملخص الأقساط'),
                _buildSummaryCard(summary),
              ],

              // Document Images
              if (displayCustomer.idCardFrontUrl != null ||
                  displayCustomer.idCardBackUrl != null ||
                  displayCustomer.residenceFrontUrl != null ||
                  displayCustomer.residenceBackUrl != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('المستمسكات'),
                _buildDocumentsGrid(displayCustomer),
              ],

              // Installment Plans Table
              if (plans.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('الأقساط'),
                _buildInstallmentsTable(plans),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Call customer
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text(
                        'اتصال',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: WhatsApp
                      },
                      icon: const Icon(Icons.message),
                      label: const Text(
                        'واتساب',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electric,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final totalDebt = summary['total_debt'] ?? 0;
    final totalPaid = summary['total_paid'] ?? 0;
    final remaining = summary['remaining_balance'] ?? 0;
    final active = summary['active_installments'] ?? 0;

    return Card(
      color: AppColors.navy.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('إجمالي الديون', totalDebt, Colors.red),
                ),
                Expanded(
                  child: _buildStatItem('المدفوع', totalPaid, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('المتبقي', remaining, AppColors.navy),
                ),
                Expanded(
                  child:
                      _buildStatItem('أقساط نشطة', active, AppColors.electric),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsGrid(CustomerModel customer) {
    final documents = [
      if (customer.idCardFrontUrl != null)
        {'url': customer.idCardFrontUrl!, 'label': 'الهوية (أمامي)'},
      if (customer.idCardBackUrl != null)
        {'url': customer.idCardBackUrl!, 'label': 'الهوية (خلفي)'},
      if (customer.residenceFrontUrl != null)
        {'url': customer.residenceFrontUrl!, 'label': 'السكن (أمامي)'},
      if (customer.residenceBackUrl != null)
        {'url': customer.residenceBackUrl!, 'label': 'السكن (خلفي)'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return GestureDetector(
          onTap: () => _showImageViewer(context, doc['url']!, doc['label']!),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    doc['url']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        doc['label']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
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
      },
    );
  }

  void _showImageViewer(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(label, style: const TextStyle(fontFamily: 'Tajawal')),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(url, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentsTable(List<dynamic> plans) {
    debugPrint('📊 Building installments table with ${plans.length} plans');

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: plans.map((plan) {
            debugPrint('🔍 Processing plan: $plan');

            // Try multiple field names for product name
            final productName = plan['product_name'] ??
                plan['product'] ??
                plan['item_name'] ??
                plan['name'] ??
                plan['title'] ??
                'منتج غير معروف';

            // Enhanced parsing for numeric values
            double parseAmount(dynamic value) {
              if (value == null || value == '') return 0;
              if (value is num) return value.toDouble();
              if (value is String) {
                // Remove commas, spaces, and currency symbols
                String cleanValue = value
                    .replaceAll(',', '')
                    .replaceAll(' ', '')
                    .replaceAll('ريال', '')
                    .replaceAll('ر.س', '')
                    .replaceAll('SAR', '')
                    .replaceAll(r'$', '');
                return double.tryParse(cleanValue) ?? 0;
              }
              return 0;
            }

            // Try multiple field names for amounts
            final totalAmount = parseAmount(plan['total_amount'] ??
                plan['total'] ??
                plan['amount'] ??
                plan['price'] ??
                plan['loan_amount'] ??
                plan['principal']);

            final paidAmount = parseAmount(plan['paid_amount'] ??
                plan['paid'] ??
                plan['amount_paid'] ??
                plan['payments_total'] ??
                plan['total_paid']);

            final remainingAmount = parseAmount(plan['remaining_amount'] ??
                plan['remaining'] ??
                plan['balance'] ??
                plan['outstanding']);

            // Calculate remaining if not provided
            final remaining = remainingAmount > 0
                ? remainingAmount
                : totalAmount - paidAmount;

            final status =
                plan['status']?.toString().toLowerCase() ?? 'unknown';
            final planId =
                plan['id']?.toString() ?? plan['installment_id']?.toString();

            debugPrint(
                '💰 Parsed amounts - Total: $totalAmount, Paid: $paidAmount, Remaining: $remaining');

            Color statusColor;
            String statusText;
            switch (status) {
              case 'active':
              case 'ongoing':
              case 'pending':
                statusColor = Colors.green;
                statusText = 'نشط';
                break;
              case 'overdue':
              case 'late':
              case 'delayed':
                statusColor = Colors.red;
                statusText = 'متأخر';
                break;
              case 'completed':
              case 'finished':
              case 'paid':
              case 'closed':
                statusColor = Colors.blue;
                statusText = 'مكتمل';
                break;
              default:
                statusColor = Colors.grey;
                statusText = 'معلق';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPlanStat(
                          'الإجمالي', totalAmount.toStringAsFixed(0)),
                      _buildPlanStat('المدفوع', paidAmount.toStringAsFixed(0)),
                      _buildPlanStat('المتبقي', remaining.toStringAsFixed(0),
                          isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // View Details Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _navigateToInstallmentDetails(context, planId);
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text(
                        'عرض تفاصيل القسط',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateToInstallmentDetails(BuildContext context, String? planId) {
    if (planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'معرف القسط غير متوفر',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
      return;
    }

    // TODO: Navigate to installment details screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => InstallmentDetailsScreen(planId: planId),
    //   ),
    // );

    // For now, show a placeholder message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('تفاصيل القسط', style: TextStyle(fontFamily: 'Tajawal')),
        content: Text(
          'معرف القسط: $planId\n\n(سيتم ربط شاشة التفاصيل قريباً)',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStat(String label, String value,
      {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? AppColors.danger : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.navy),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
