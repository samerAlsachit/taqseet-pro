import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/customer_model.dart';
import '../services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final CustomerModel? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();

  // Image paths
  String? _customerImagePath;
  String? _docFrontPath;
  String? _docBackPath;
  String? _residenceCardPath;

  final ImagePicker _imagePicker = ImagePicker();

  // Check if we're in edit mode
  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if in edit mode
    if (_isEditMode) {
      _nameController.text = widget.customer!.fullName;
      _phoneController.text = widget.customer!.phone;
      _nationalIdController.text = widget.customer!.nationalId ?? '';
      _addressController.text = widget.customer!.address;
      _customerImagePath = widget.customer!.customerImagePath;
      _docFrontPath = widget.customer!.docFrontPath;
      _docBackPath = widget.customer!.docBackPath;
      _residenceCardPath = widget.customer!.residenceCardPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Save image to permanent storage
  Future<String?> _saveImagePermanently(
    XFile pickedFile,
    String fileName,
  ) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String customerDir = path.join(appDir.path, 'customer_images');

      // Create directory if it doesn't exist
      final Directory dir = Directory(customerDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String filePath = path.join(customerDir, fileName);
      final File newImage = await File(pickedFile.path).copy(filePath);

      return newImage.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في حفظ الصورة: $e',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Show modal to choose image source (camera or gallery)
  void _showImageSourceModal(String imageType, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A192F),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF0A192F)),
              title: const Text(
                'التقاط صورة الآن',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              subtitle: const Text(
                'استخدام الكاميرا',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(imageType, ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFF0A192F)),
              title: const Text(
                'اختيار من المعرض',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              subtitle: const Text(
                'استخدام الاستوديو',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(imageType, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F9FB),
                  foregroundColor: const Color(0xFF0A192F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera or gallery and save permanently
  Future<void> _pickImage(String imageType, ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String fileName = '${imageType}_$timestamp.jpg';

        final String? savedPath = await _saveImagePermanently(
          pickedFile,
          fileName,
        );

        if (savedPath != null) {
          setState(() {
            switch (imageType) {
              case 'customer':
                _customerImagePath = savedPath;
                break;
              case 'doc_front':
                _docFrontPath = savedPath;
                break;
              case 'doc_back':
                _docBackPath = savedPath;
                break;
              case 'residence':
                _residenceCardPath = savedPath;
                break;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في التقاط الصورة: $e',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete captured image
  void _deleteImage(String imageType) {
    setState(() {
      switch (imageType) {
        case 'customer':
          _customerImagePath = null;
          break;
        case 'doc_front':
          _docFrontPath = null;
          break;
        case 'doc_back':
          _docBackPath = null;
          break;
        case 'residence':
          _residenceCardPath = null;
          break;
      }
    });
  }

  /// Show options to retake or delete image
  void _showImageOptions(String imageType, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A192F),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                LucideIcons.refreshCw,
                color: Color(0xFF0A192F),
              ),
              title: const Text(
                'إعادة التقاط / تغيير',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceModal(imageType, title);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text(
                'حذف الصورة',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteImage(imageType);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F9FB),
                  foregroundColor: const Color(0xFF0A192F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Tajawal'),
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronRight, color: Color(0xFF0A192F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'تعديل بيانات العميل' : 'إضافة عميل جديد',
          style: const TextStyle(
            color: Color(0xFF0A192F),
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionTitle('البيانات الأساسية'),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'اسم العميل',
                controller: _nameController,
                icon: LucideIcons.user,
                hint: 'أدخل اسم العميل الكامل',
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'رقم الهاتف',
                controller: _phoneController,
                icon: LucideIcons.phone,
                hint: 'مثال: 0770 123 4567',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'الرقم الوطني',
                controller: _nationalIdController,
                icon: LucideIcons.contact,
                hint: 'أدخل الرقم الوطني للعميل',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'العنوان',
                controller: _addressController,
                icon: LucideIcons.mapPin,
                hint: 'أدخل عنوان العميل',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Photo Documentation Section
              _buildSectionTitle('التوثيق الصوري'),
              const SizedBox(height: 8),
              const Text(
                'التقط صور المستمسكات للتوثيق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // Customer Profile Photo (Large Circle)
              Center(
                child: _buildCircularImageCard(
                  label: 'صورة العميل الشخصية',
                  imagePath: _customerImagePath,
                  onTap: () {
                    if (_customerImagePath != null) {
                      _showImageOptions('customer', 'صورة العميل الشخصية');
                    } else {
                      _showImageSourceModal('customer', 'صورة العميل الشخصية');
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Document Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildDocumentCard(
                      label: 'واجهة الهوية',
                      imagePath: _docFrontPath,
                      onTap: () {
                        if (_docFrontPath != null) {
                          _showImageOptions('doc_front', 'واجهة الهوية');
                        } else {
                          _showImageSourceModal('doc_front', 'واجهة الهوية');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDocumentCard(
                      label: 'ظهر الهوية',
                      imagePath: _docBackPath,
                      onTap: () {
                        if (_docBackPath != null) {
                          _showImageOptions('doc_back', 'ظهر الهوية');
                        } else {
                          _showImageSourceModal('doc_back', 'ظهر الهوية');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDocumentCard(
                      label: 'بطاقة السكن',
                      imagePath: _residenceCardPath,
                      onTap: () {
                        if (_residenceCardPath != null) {
                          _showImageOptions('residence', 'بطاقة السكن');
                        } else {
                          _showImageSourceModal('residence', 'بطاقة السكن');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
          maxLines: maxLines,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: Color(0xFF0A192F),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'هذا الحقل مطلوب';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF0A192F), size: 20),
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
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
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

  /// Build circular image card for customer profile
  Widget _buildCircularImageCard({
    required String label,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: hasImage ? null : Colors.white,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: hasImage
                    ? const Color(0xFF0A192F)
                    : const Color(0xFFE2E8F0),
                width: hasImage ? 3 : 2,
              ),
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: !hasImage
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.camera,
                        color: Color(0xFF0A192F),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'التقاط',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'إعادة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// Build document card
  Widget _buildDocumentCard({
    required String label,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: hasImage ? null : Colors.white,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.camera,
                        color: Color(0xFF0A192F),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Color(0xFF64748B),
                          fontSize: 11,
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
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'إعادة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSaving = false;

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isSaving = true);

                  final customerService = CustomerService();

                  try {
                    if (_isEditMode) {
                      // تحديث عميل موجود
                      final result = await customerService.updateCustomer(
                        customerId: widget.customer!.id,
                        fullName: _nameController.text,
                        phone: _phoneController.text,
                        nationalId: _nationalIdController.text.isNotEmpty
                            ? _nationalIdController.text
                            : null,
                        address: _addressController.text,
                        customerImagePath: _customerImagePath,
                        docFrontPath: _docFrontPath,
                        docBackPath: _docBackPath,
                        residenceCardPath: _residenceCardPath,
                        existingAvatarUrl: widget.customer!.avatarUrl,
                        existingDocumentsUrls: widget.customer!.documentsUrls,
                      );

                      if (!result['success']) {
                        throw Exception(result['message']);
                      }

                      // استخراج الروابط الجديدة من الاستجابة
                      final responseData = result['data'] ?? {};
                      final customer = CustomerModel(
                        id: widget.customer!.id,
                        fullName: _nameController.text,
                        phone: _phoneController.text,
                        nationalId: _nationalIdController.text.isNotEmpty
                            ? _nationalIdController.text
                            : null,
                        address: _addressController.text,
                        customerImagePath: _customerImagePath,
                        docFrontPath: _docFrontPath,
                        docBackPath: _docBackPath,
                        residenceCardPath: _residenceCardPath,
                        avatarUrl:
                            responseData['avatar_url'] ??
                            widget.customer!.avatarUrl,
                        documentsUrls: responseData['documents_urls'] != null
                            ? List<String>.from(responseData['documents_urls'])
                            : widget.customer!.documentsUrls,
                        createdAt: widget.customer!.createdAt,
                        updatedAt: DateTime.now(),
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم تحديث بيانات العميل بنجاح!',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                            backgroundColor: Color(0xFF0A192F),
                          ),
                        );
                        Navigator.pop(context, customer);
                      }
                    } else {
                      // ✅ الخطوة 1: رفع الصور أولاً إلى Supabase Storage
                      String? avatarUrl;
                      List<String> documentsUrls = [];

                      // رفع صورة العميل (الصورة الشخصية)
                      if (_customerImagePath != null &&
                          _customerImagePath!.isNotEmpty) {
                        avatarUrl = await customerService.uploadImage(
                          _customerImagePath!,
                          folder: 'avatars',
                        );
                        if (avatarUrl == null) {
                          throw Exception(
                            'فشل رفع صورة العميل إلى Supabase Storage. '
                            'تحقق من: 1) اتصال الإنترنت 2) تسجيل الدخول 3) صلاحيات البكت',
                          );
                        }
                      }

                      // رفع صور المستمسكات
                      final docPaths =
                          [_docFrontPath, _docBackPath, _residenceCardPath]
                              .where((path) => path != null && path.isNotEmpty)
                              .toList();

                      if (docPaths.isNotEmpty) {
                        final docUrls = await customerService.uploadImages(
                          docPaths.cast<String>(),
                          folder: 'documents',
                        );
                        documentsUrls = docUrls;
                      }

                      // ✅ الخطوة 2: إنشاء العميل مع روابط الصور
                      final result = await customerService.createCustomer(
                        fullName: _nameController.text,
                        phone: _phoneController.text,
                        nationalId: _nationalIdController.text.isNotEmpty
                            ? _nationalIdController.text
                            : null,
                        address: _addressController.text,
                        customerImagePath: _customerImagePath,
                        docFrontPath: _docFrontPath,
                        docBackPath: _docBackPath,
                        residenceCardPath: _residenceCardPath,
                        avatarUrl: avatarUrl,
                        documentsUrls: documentsUrls.isNotEmpty
                            ? documentsUrls
                            : null,
                      );

                      if (!result['success']) {
                        throw Exception(result['message']);
                      }

                      // السيرفر يرجع UUID جديد والروابط
                      final responseData = result['data'] ?? {};
                      final newCustomerId = responseData['id'] ?? '';

                      final customer = CustomerModel(
                        id: newCustomerId,
                        fullName: _nameController.text,
                        phone: _phoneController.text,
                        nationalId: _nationalIdController.text.isNotEmpty
                            ? _nationalIdController.text
                            : null,
                        address: _addressController.text,
                        customerImagePath: _customerImagePath,
                        docFrontPath: _docFrontPath,
                        docBackPath: _docBackPath,
                        residenceCardPath: _residenceCardPath,
                        avatarUrl: responseData['avatar_url'] ?? avatarUrl,
                        documentsUrls: responseData['documents_urls'] != null
                            ? List<String>.from(responseData['documents_urls'])
                            : documentsUrls.isNotEmpty
                            ? documentsUrls
                            : null,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إضافة العميل بنجاح!',
                              style: TextStyle(fontFamily: 'Tajawal'),
                            ),
                            backgroundColor: Color(0xFF0A192F),
                          ),
                        );
                        Navigator.pop(context, customer);
                      }
                    }
                  } catch (e) {
                    // ✅ معالجة خاصة لخطأ رفع الصورة - عرض رسالة الخطأ الحقيقية
                    final errorMsg = e.toString();
                    // طباعة الخطأ الكامل في الترمنال للتشخيص
                    print('Detailed Storage Error: $e');
                    // عرض رسالة الخطأ الحقيقية القادمة من السيرفر
                    final displayMessage = errorMsg.isNotEmpty
                        ? '❌ $errorMsg'
                        : 'حدث خطأ غير متوقع أثناء رفع الصورة';

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            displayMessage,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 5),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A192F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.check, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'تحديث البيانات' : 'حفظ العميل',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
