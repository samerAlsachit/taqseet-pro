import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import 'add_customer_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailsScreen({super.key, required this.customer});

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

    return Row(
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
