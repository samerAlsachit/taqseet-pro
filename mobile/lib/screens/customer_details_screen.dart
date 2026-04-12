import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../models/installment_plan_model.dart';
import '../models/payment_schedule_model.dart';
import '../services/thabit_local_db_service.dart';
import '../services/thabit_pull_sync_service.dart';
import 'add_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final ThabitLocalDBService _thabitDB = ThabitLocalDBService();
  final ThabitPullSyncService _thabitSync = ThabitPullSyncService();
  bool _isGeneratingStatement = false;

  CustomerModel get customer => widget.customer;

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
          'تفاصيل العميل',
          style: TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: Color(0xFF0A192F)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCustomerScreen(customer: customer),
                ),
              );
              // If customer was updated, pop back to refresh
              if (result != null &&
                  result is CustomerModel &&
                  context.mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Profile
            _buildHeaderSection(context),
            const SizedBox(height: 24),

            // Financial Summary Section
            _buildSectionTitle('الملخص المالي'),
            const SizedBox(height: 16),
            _buildFinancialSummary(),
            const SizedBox(height: 24),

            // Document Gallery Section
            _buildSectionTitle('المستمسكات الرسمية'),
            const SizedBox(height: 16),
            _buildDocumentGallery(context),
            const SizedBox(height: 24),

            // Address Section
            _buildSectionTitle('معلومات الاتصال'),
            const SizedBox(height: 16),
            _buildAddressCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          _buildProfileImage(context),
          const SizedBox(height: 16),
          // Name
          Text(
            customer.name,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A192F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Phone with Call Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.phone, color: Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
              Text(
                customer.phone,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              // Call Button
              GestureDetector(
                onTap: () => _makePhoneCall(customer.phone),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.phoneCall,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final bool hasImage =
        customer.customerImagePath != null &&
        customer.customerImagePath!.isNotEmpty;

    return GestureDetector(
      onTap: hasImage
          ? () => _openFullScreenImage(
              context,
              customer.customerImagePath!,
              'صورة العميل',
            )
          : null,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: hasImage ? null : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(60),
          border: Border.all(
            color: hasImage ? const Color(0xFF0A192F) : const Color(0xFFE2E8F0),
            width: hasImage ? 3 : 2,
          ),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(customer.customerImagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: !hasImage
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.user, color: Color(0xFF94A3B8), size: 40),
                  SizedBox(height: 4),
                  Text(
                    'لا توجد صورة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Zoom indicator
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A192F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.zoomIn,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    // Mock financial data - in real app, this would come from customer model
    const double totalDebt = 2500000;
    const double collected = 750000;
    const double remaining = totalDebt - collected;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                title: 'إجمالي الديون',
                amount: totalDebt,
                icon: LucideIcons.wallet,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                title: 'المحصل',
                amount: collected,
                icon: LucideIcons.arrowDownCircle,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                title: 'المتبقي',
                amount: remaining,
                icon: LucideIcons.creditCard,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Share Statement Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingStatement ? null : _downloadStatement,
            icon: _isGeneratingStatement
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.share2, size: 18),
            label: Text(
              _isGeneratingStatement
                  ? 'جاري تجهيز الكشف...'
                  : 'مشاركة كشف الحساب',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A192F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final formattedAmount = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedAmount,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGallery(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDocumentImageCard(
            context: context,
            label: 'واجهة الهوية',
            imagePath: customer.docFrontPath,
            placeholderIcon: LucideIcons.fileText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDocumentImageCard(
            context: context,
            label: 'ظهر الهوية',
            imagePath: customer.docBackPath,
            placeholderIcon: LucideIcons.fileText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDocumentImageCard(
            context: context,
            label: 'بطاقة السكن',
            imagePath: customer.residenceCardPath,
            placeholderIcon: LucideIcons.home,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentImageCard({
    required BuildContext context,
    required String label,
    required String? imagePath,
    required IconData placeholderIcon,
  }) {
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    return GestureDetector(
      onTap: hasImage
          ? () => _openFullScreenImage(context, imagePath, label)
          : null,
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: hasImage ? null : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: hasImage
                    ? const Color(0xFF0A192F)
                    : const Color(0xFFE2E8F0),
                width: hasImage ? 2 : 1,
              ),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        placeholderIcon,
                        color: const Color(0xFF94A3B8),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'لا توجد صورة',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                      const Icon(
                        LucideIcons.zoomIn,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A192F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: Color(0xFF0A192F),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'العنوان',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.address,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _openFullScreenImage(
    BuildContext context,
    String imagePath,
    String title,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenImageViewer(imagePath: imagePath, title: title),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  /// Generate and share customer statement as image
  /// Uses Thabit system: installment_plans + payment_schedule
  Future<void> _downloadStatement() async {
    setState(() => _isGeneratingStatement = true);

    try {
      // Initialize Thabit DB
      await _thabitDB.init();

      print(
        '🔍 CustomerDetails: Looking for data for customer ID "${customer.id}"',
      );

      // 1. Get installment plans for this customer
      List<InstallmentPlanModel> plans = _thabitDB
          .getInstallmentPlansByCustomer(customer.id);
      print('📊 CustomerDetails: Found ${plans.length} installment plans');

      // 2. Get payment schedules for all plans (this contains due_date!)
      List<PaymentScheduleModel> allSchedules = [];
      for (final plan in plans) {
        final schedules = _thabitDB.getPaymentScheduleByPlan(plan.id);
        allSchedules.addAll(schedules);
      }
      print(
        '📊 CustomerDetails: Found ${allSchedules.length} payment schedules',
      );

      // 3. If no local data, fetch from Supabase
      if (plans.isEmpty || allSchedules.isEmpty) {
        print('🌐 CustomerDetails: No local data, fetching from Supabase...');
        await _thabitSync.init();
        final success = await _thabitSync.fetchCustomerData(customer.id);

        if (success) {
          // Re-fetch from local DB after sync
          plans = _thabitDB.getInstallmentPlansByCustomer(customer.id);
          allSchedules = [];
          for (final plan in plans) {
            final schedules = _thabitDB.getPaymentScheduleByPlan(plan.id);
            allSchedules.addAll(schedules);
          }
          print(
            '📊 CustomerDetails: After sync - ${plans.length} plans, ${allSchedules.length} schedules',
          );
        }
      }

      // 4. If still no data, show dialog
      if (plans.isEmpty || allSchedules.isEmpty) {
        print('❌ CustomerDetails: No data found after all attempts');
        if (mounted) {
          setState(() => _isGeneratingStatement = false);
          _showNoInstallmentsDialog();
        }
        return;
      }

      // 5. Calculate totals
      final totalFinanced = plans.fold<int>(
        0,
        (sum, p) => sum + p.financedAmount,
      );
      final totalPaid = allSchedules.fold<int>(
        0,
        (sum, s) => sum + (s.paidAmount ?? 0),
      );
      final totalRemaining = totalFinanced - totalPaid;

      print('✅ CustomerDetails: Statement ready');
      print('   Plans: ${plans.length}');
      print('   Schedules: ${allSchedules.length}');
      print('   Total Financed: $totalFinanced');
      print('   Total Paid: $totalPaid');
      print('   Remaining: $totalRemaining');

      // Show preparing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تجهيز الكشف، جارٍ فتح المشاركة...',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // TODO: Update ImageService to handle PaymentScheduleModel
      // For now, we'll use a placeholder message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم جلب البيانات بنجاح: ${allSchedules.length} قسط',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      /*
      // Generate and share statement as image
      await _imageService.generateAndShareStatement(
        storeName: 'مرساة',
        customerName: customer.name,
        customerPhone: customer.phone,
        paymentSchedules: allSchedules, // TODO: Update ImageService
        totalFinanced: totalFinanced,
        totalPaid: totalPaid,
        remainingBalance: totalRemaining,
      );
      */
    } catch (e) {
      print('❌ CustomerDetails: Error generating statement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر إنشاء الكشف: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingStatement = false);
      }
    }
  }

  /// Show dialog when no installments found with option to clear cache and re-fetch
  void _showNoInstallmentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'لا توجد أقساط مسجلة',
          style: TextStyle(fontFamily: 'Tajawal'),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'لم يتم العثور على أقساط لهذا العميل. قد يكون السبب:\n\n'
          '• البيانات محلية (LocalDB) فارغة\n'
          '• اسم الجدول في Supabase تغير\n\n'
          'هل تريد مسح البيانات المحلية وجلبها من جديد؟',
          style: TextStyle(fontFamily: 'Tajawal'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAndRefetchData();
            },
            child: const Text(
              'مسح وجلب من جديد',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  /// Clear local data and re-fetch from Supabase using Thabit system
  Future<void> _clearAndRefetchData() async {
    setState(() => _isGeneratingStatement = true);

    try {
      await _thabitSync.init();

      // Clear cache and fetch fresh data
      final success = await _thabitSync.fetchCustomerData(customer.id);

      if (success) {
        // Get the data to show counts
        final plans = _thabitDB.getInstallmentPlansByCustomer(customer.id);
        List<PaymentScheduleModel> allSchedules = [];
        for (final plan in plans) {
          final schedules = _thabitDB.getPaymentScheduleByPlan(plan.id);
          allSchedules.addAll(schedules);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم جلب ${plans.length} خطة و ${allSchedules.length} قسط من Supabase',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'لا توجد أقساط في Supabase لهذا العميل',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error re-fetching: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب البيانات: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingStatement = false);
      }
    }
  }
}

/// Full Screen Image Viewer with Zoom Capability
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Hero(
            tag: imagePath,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
