import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/customer_model.dart';
import '../services/thabit_local_db_service.dart';
import '../services/marsa_sync_service.dart';
import '../services/customer_service.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ThabitLocalDBService _localDB = ThabitLocalDBService();
  final MarsaSyncService _marsaSync = MarsaSyncService();
  final CustomerService _customerService = CustomerService();

  String _searchQuery = '';
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  /// Initialize services and load data
  Future<void> _initializeAndLoadData() async {
    try {
      await _localDB.init();
      await _marsaSync.init();
      await _loadCustomers();
    } catch (e) {
      setState(() {
        _error = 'خطأ في تهيئة قاعدة البيانات: $e';
        _isLoading = false;
      });
    }
  }

  /// Load customers from local DB and sync with Supabase
  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, try to sync from API
      if (await _isOnline()) {
        setState(() => _isSyncing = true);
        await _marsaSync.fetchSync();
        setState(() => _isSyncing = false);
      }

      // Load customers from local Hive box
      final customersData = _localDB.getAllCustomers();

      // Calculate debt and installments for each customer
      final enrichedCustomers = await _enrichCustomerData(customersData);

      setState(() {
        _customers = enrichedCustomers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
        _isSyncing = false;
      });
    }
  }

  /// Enrich customer data with debt and installments count
  Future<List<Map<String, dynamic>>> _enrichCustomerData(
    List<Map<String, dynamic>> customers,
  ) async {
    final enriched = <Map<String, dynamic>>[];

    for (final customerData in customers) {
      final customerId = customerData['id']?.toString() ?? '';

      // Get installment plans for this customer from local DB
      final plans = _localDB.getInstallmentPlansByCustomer(customerId);

      // Calculate total debt (remaining amount)
      double totalDebt = 0;
      for (final plan in plans) {
        totalDebt += plan.remainingAmount;
      }

      enriched.add({
        'customer': CustomerModel.fromJson(customerData),
        'totalDebt': totalDebt,
        'installmentsCount': plans.length,
        'rawData': customerData,
      });
    }

    return enriched;
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) {
      final customer = c['customer'] as CustomerModel;
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.phone.contains(_searchQuery);
    }).toList();
  }

  String _formatNumber(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'العملاء',
          style: TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sync Indicator
          if (_isSyncing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF0A192F).withValues(alpha: 0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0A192F),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'جاري المزامنة مع السحابة...',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Color(0xFF0A192F),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'البحث عن عميل...',
                hintStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
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
          ),

          // Stats Summary
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي العملاء',
                      '${_customers.length}',
                      LucideIcons.users,
                      const Color(0xFF0A192F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي الديون',
                      '${_formatNumber(_customers.fold<double>(0, (sum, c) => sum + (c['totalDebt'] as num).toDouble()))} د.ع',
                      LucideIcons.wallet,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0A192F)),
                        SizedBox(height: 16),
                        Text(
                          'جاري تحميل البيانات...',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 64,
                          color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCustomers,
                          icon: const Icon(LucideIcons.refreshCw),
                          label: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(fontFamily: 'Tajawal'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A192F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredCustomers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    color: const Color(0xFF0A192F),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerCard(filteredCustomers[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          if (result != null && result is Map<String, dynamic>) {
            final shouldRefresh = result['shouldRefresh'] as bool? ?? false;
            if (shouldRefresh) {
              // Refresh data after adding a customer
              await _loadCustomers();
            }
          }
        },
        backgroundColor: const Color(0xFF0A192F),
        icon: const Icon(LucideIcons.userPlus, color: Colors.white),
        label: const Text(
          'عميل جديد',
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A192F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customerData) {
    final customer = customerData['customer'] as CustomerModel;
    final totalDebt = (customerData['totalDebt'] as num).toDouble();
    final installmentsCount = customerData['installmentsCount'] as int;
    final hasDebt = totalDebt > 0;

    // ✅ Log image URL being loaded
    print('UI Image Link: ${customer.profileImageUrl}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ✅ عرض صورة العميل من Supabase أو أيقونة افتراضية
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A192F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: customer.profileImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(
                            0xFF0A192F,
                          ).withValues(alpha: 0.05),
                          child: const Center(
                            child: Icon(
                              LucideIcons.user,
                              color: Color(0xFF0A192F),
                              size: 24,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(
                            0xFF0A192F,
                          ).withValues(alpha: 0.05),
                          child: const Icon(
                            LucideIcons.user,
                            color: Color(0xFF0A192F),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A192F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.phone,
                              size: 14,
                              color: const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.phone,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      LucideIcons.moreVertical,
                      color: Color(0xFF64748B),
                    ),
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerDetailsScreen(customer: customer),
                          ),
                        );
                      } else if (value == 'edit') {
                        // ✅ فتح شاشة التعديل
                        _editCustomer(customer);
                      } else if (value == 'delete') {
                        // ✅ تنفيذ الحذف
                        _deleteCustomer(customer);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(LucideIcons.eye, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'عرض التفاصيل',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit2, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'تعديل',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'حذف',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    customer.address,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasDebt
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'الديون المستحقة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: hasDebt
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasDebt
                                ? '${_formatNumber(totalDebt)} د.ع'
                                : 'لا يوجد',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasDebt
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'عدد الأقساط',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$installmentsCount قسط',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A192F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ دالة لعرض SnackBar في الأعلى (Top Banner)
  void _showTopSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: isError ? Colors.red : const Color(0xFF0A192F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// ✅ دالة حذف العميل مع إعادة تحميل القائمة
  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Text(
          'هل أنت متأكد من حذف العميل ${customer.fullName}؟\nسيتم حذف جميع البيانات والصور المتعلقة به.',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final result = await _customerService.deleteCustomerWithImages(
          customer.id,
          idDocUrl: customer.idDocUrl,
          documentsUrls: customer.documentsUrls,
        );

        if (result['success'] == true) {
          _showTopSnackBar('تم حذف العميل بنجاح');
          // ✅ إعادة تحميل القائمة بعد الحذف
          await _loadCustomers();
        } else {
          _showTopSnackBar(
            result['message'] ?? 'فشل حذف العميل',
            isError: true,
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        _showTopSnackBar('حدث خطأ أثناء الحذف: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ دالة تعديل العميل (فتح شاشة التعديل)
  Future<void> _editCustomer(CustomerModel customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(customer: customer),
      ),
    );

    // ✅ إذا تم التعديل بنجاح، أعد تحميل القائمة
    if (result != null && result is CustomerModel && mounted) {
      _showTopSnackBar('تم تعديل العميل بنجاح');
      await _loadCustomers();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد عملاء',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف عملاء جدد للبدء',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
