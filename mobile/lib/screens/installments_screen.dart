import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import 'add_installment_screen.dart';

class InstallmentModel {
  final String id;
  final String customerName;
  final String? phoneNumber; // For WhatsApp notifications
  final double totalAmount;
  final double remainingAmount;
  final double monthlyPayment;
  final int totalMonths;
  final int paidMonths;
  final DateTime nextPaymentDate;
  final String status; // 'active', 'completed', 'overdue'

  InstallmentModel({
    required this.id,
    required this.customerName,
    this.phoneNumber,
    required this.totalAmount,
    required this.remainingAmount,
    required this.monthlyPayment,
    required this.totalMonths,
    required this.paidMonths,
    required this.nextPaymentDate,
    required this.status,
  });
}

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data with phone numbers for WhatsApp
  List<InstallmentModel> installments = [
    InstallmentModel(
      id: '1',
      customerName: 'أحمد محمد العبيدي',
      phoneNumber: '07701234567',
      totalAmount: 1850000,
      remainingAmount: 925000,
      monthlyPayment: 185000,
      totalMonths: 10,
      paidMonths: 5,
      nextPaymentDate: DateTime.now().add(const Duration(days: 5)),
      status: 'active',
    ),
    InstallmentModel(
      id: '2',
      customerName: 'علي حسين الكاظمي',
      phoneNumber: '07709876543',
      totalAmount: 950000,
      remainingAmount: 0,
      monthlyPayment: 237500,
      totalMonths: 4,
      paidMonths: 4,
      nextPaymentDate: DateTime.now(),
      status: 'completed',
    ),
    InstallmentModel(
      id: '3',
      customerName: 'محمد علي الساعدي',
      phoneNumber: '07705678901',
      totalAmount: 2450000,
      remainingAmount: 1470000,
      monthlyPayment: 245000,
      totalMonths: 10,
      paidMonths: 4,
      nextPaymentDate: DateTime.now().subtract(const Duration(days: 3)),
      status: 'overdue',
    ),
    InstallmentModel(
      id: '4',
      customerName: 'حسين علي التكريتي',
      phoneNumber: '07703456789',
      totalAmount: 1250000,
      remainingAmount: 625000,
      monthlyPayment: 156250,
      totalMonths: 8,
      paidMonths: 4,
      nextPaymentDate: DateTime.now().add(const Duration(days: 12)),
      status: 'active',
    ),
    InstallmentModel(
      id: '5',
      customerName: 'فاطمة أحمد الجبوري',
      phoneNumber: '07702345678',
      totalAmount: 750000,
      remainingAmount: 0,
      monthlyPayment: 150000,
      totalMonths: 5,
      paidMonths: 5,
      nextPaymentDate: DateTime.now(),
      status: 'completed',
    ),
    InstallmentModel(
      id: '6',
      customerName: 'عمر محمد السامرائي',
      totalAmount: 3200000,
      remainingAmount: 2560000,
      monthlyPayment: 320000,
      totalMonths: 10,
      paidMonths: 2,
      nextPaymentDate: DateTime.now().subtract(const Duration(days: 7)),
      status: 'overdue',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<InstallmentModel> getFilteredInstallments(String status) {
    List<InstallmentModel> filtered = installments;

    if (status == 'active') {
      filtered = installments.where((i) => i.status == 'active').toList();
    } else if (status == 'completed') {
      filtered = installments.where((i) => i.status == 'completed').toList();
    } else if (status == 'overdue') {
      filtered = installments.where((i) => i.status == 'overdue').toList();
    }

    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (i) =>
              i.customerName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  String _formatNumber(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'overdue':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'overdue':
        return 'متأخر';
      default:
        return 'غير معروف';
    }
  }

  /// Send WhatsApp reminder message
  Future<void> _sendWhatsAppReminder(InstallmentModel installment) async {
    if (installment.phoneNumber == null || installment.phoneNumber!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لا يوجد رقم هاتف لهذا الزبون',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Format phone number (remove leading zero and add country code)
    String phoneNumber = installment.phoneNumber!;
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '964${phoneNumber.substring(1)}';
    }

    // Format message
    final formattedAmount = _formatNumber(installment.monthlyPayment);
    final formattedDate = intl.DateFormat(
      'yyyy/MM/dd',
    ).format(installment.nextPaymentDate);
    final message =
        'السلام عليكم سيد ${installment.customerName}، نود تذكيرك بموعد قسطك القادم بمبلغ $formattedAmount د.ع والمستحق بتاريخ $formattedDate. شكراً لثقتكم بمحل مرساة.';

    // Create WhatsApp URL
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Try WhatsApp scheme as fallback
        final Uri whatsappAppUrl = Uri.parse(
          'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(whatsappAppUrl)) {
          await launchUrl(whatsappAppUrl);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'لا يمكن فتح WhatsApp. تأكد من تثبيت التطبيق.',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الأقساط',
          style: TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0A192F),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0A192F),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal'),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'مكتمل'),
            Tab(text: 'متأخر'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'البحث عن قسط...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'إجمالي الأقساط',
                    '${installments.length}',
                    LucideIcons.fileText,
                    const Color(0xFF0A192F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'المتأخرة',
                    '${installments.where((i) => i.status == 'overdue').length}',
                    LucideIcons.alertCircle,
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInstallmentsList('all'),
                _buildInstallmentsList('completed'),
                _buildInstallmentsList('overdue'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddInstallmentScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF0A192F),
        tooltip: 'إضافة قسط جديد',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'إضافة قسط جديد',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A192F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsList(String filter) {
    final filtered = getFilteredInstallments(filter);

    if (filtered.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildInstallmentCard(filtered[index]);
      },
    );
  }

  Widget _buildInstallmentCard(InstallmentModel installment) {
    final statusColor = _getStatusColor(installment.status);
    final daysRemaining = installment.nextPaymentDate
        .difference(DateTime.now())
        .inDays;
    final isOverdue = daysRemaining < 0;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    installment.status == 'completed'
                        ? LucideIcons.checkCircle2
                        : installment.status == 'overdue'
                        ? LucideIcons.alertCircle
                        : LucideIcons.clock,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        installment.customerName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(installment.status),
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
                ),
                // WhatsApp Button (only for active/overdue installments)
                if (installment.status != 'completed' &&
                    installment.phoneNumber != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () => _sendWhatsAppReminder(installment),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.messageCircle,
                          color: Color(0xFF25D366),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    LucideIcons.moreVertical,
                    color: Color(0xFF64748B),
                  ),
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
                      value: 'payment',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.banknote,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'تسجيل دفعة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (installment.status != 'completed')
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.check,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'إكمال القسط',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    'المبلغ المتبقي',
                    '${_formatNumber(installment.remainingAmount)} د.ع',
                    LucideIcons.wallet,
                    const Color(0xFF0A192F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    'القسط الشهري',
                    '${_formatNumber(installment.monthlyPayment)} د.ع',
                    LucideIcons.calendar,
                    const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue
                        ? LucideIcons.alertTriangle
                        : LucideIcons.calendarClock,
                    color: isOverdue
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOverdue
                          ? 'متأخر عن الدفع بـ ${daysRemaining.abs()} يوم'
                          : 'القسط القادم: ${intl.DateFormat('yyyy/MM/dd').format(installment.nextPaymentDate)}',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: isOverdue
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: installment.paidMonths / installment.totalMonths,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${installment.paidMonths}/${installment.totalMonths}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
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

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'completed':
        message = 'لا توجد أقساط مكتملة';
        icon = LucideIcons.checkCircle2;
        break;
      case 'overdue':
        message = 'لا توجد أقساط متأخرة';
        icon = LucideIcons.alertCircle;
        break;
      default:
        message = 'لا توجد أقساط';
        icon = LucideIcons.fileText;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
