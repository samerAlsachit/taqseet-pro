import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();

  final _picker = ImagePicker();
  File? _avatarImage;
  File? _idCardFrontImage;
  File? _idCardBackImage;
  File? _residenceFrontImage;
  File? _residenceBackImage;

  String? _avatarUrl;
  String? _idCardFrontUrl;
  String? _idCardBackUrl;
  String? _residenceFrontUrl;
  String? _residenceBackUrl;

  bool _isLoading = false;
  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.customer!.fullName;
      _phoneController.text = widget.customer!.phone ?? '';
      _idNumberController.text = widget.customer!.idNumber ?? '';
      _addressController.text = widget.customer!.address ?? '';
      // Use profileImageUrl getter for unified naming pattern
      _avatarUrl =
          widget.customer!.profileImageUrl ?? widget.customer!.avatarUrl;
      _idCardFrontUrl = widget.customer!.idCardFrontUrl;
      _idCardBackUrl = widget.customer!.idCardBackUrl;
      _residenceFrontUrl = widget.customer!.residenceFrontUrl;
      _residenceBackUrl = widget.customer!.residenceBackUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(File) onPicked) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          onPicked(file);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet(Function(File) onPicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.electric.withOpacity(0.1),
                  child:
                      const Icon(Icons.camera_alt, color: AppColors.electric),
                ),
                title: const Text(
                  'التقاط صورة',
                  style: TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onPicked);
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.navy.withOpacity(0.1),
                  child: const Icon(Icons.photo_library, color: AppColors.navy),
                ),
                title: const Text(
                  'اختيار من المعرض',
                  style: TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onPicked);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<CustomerProvider>();

      final Map<String, dynamic> data = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? ''
            : _phoneController.text.trim(),
        // Send both field names for compatibility with API
        'national_id': _idNumberController.text.trim(),
        'id_number': _idNumberController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'id_doc_url': _avatarUrl,
      };

      debugPrint('📤 Sending customer data:');
      debugPrint('   full_name: ${data['full_name']}');
      debugPrint('   phone: ${data['phone']}');
      debugPrint('   national_id: ${data['national_id']}');
      debugPrint('   id_number: ${data['id_number']}');
      debugPrint('   address: ${data['address']}');

      bool success;
      if (isEditing) {
        success = await provider.updateCustomerWithFiles(
          widget.customer!.id,
          data,
          avatarFile: _avatarImage,
          idCardFrontFile: _idCardFrontImage,
          idCardBackFile: _idCardBackImage,
          residenceFrontFile: _residenceFrontImage,
          residenceBackFile: _residenceBackImage,
          oldCustomer: widget.customer,
        );
      } else {
        success = await provider.createCustomerWithFiles(
          data,
          avatarFile: _avatarImage,
          idCardFrontFile: _idCardFrontImage,
          idCardBackFile: _idCardBackImage,
          residenceFrontFile: _residenceFrontImage,
          residenceBackFile: _residenceBackImage,
        );
      }

      if (success && mounted) {
        // Force refresh customer list to show updated data immediately
        final customersProvider = context.read<CustomerProvider>();
        await customersProvider.loadCustomers(); // Refresh entire list

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تحديث العميل بنجاح' : 'تم إضافة العميل بنجاح',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'فشل في الحفظ',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text(
          isEditing ? 'تعديل عميل' : 'إضافة عميل',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              _buildSectionTitle('صورة العميل'),
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceSheet(
                      (file) => setState(() => _avatarImage = file)),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.electric.withOpacity(0.3),
                              width: 2),
                        ),
                        child: _avatarImage != null
                            ? ClipOval(
                                child: Image.file(_avatarImage!,
                                    fit: BoxFit.cover),
                              )
                            : _avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(_avatarUrl!,
                                        fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.person,
                                    size: 60, color: AppColors.navy),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.electric,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionTitle('المعلومات الأساسية'),
              _buildCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل *',
                      hint: 'أدخل الاسم الكامل',
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'الاسم مطلوب' : null,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      hint: 'أدخل رقم الهاتف',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _idNumberController,
                      label: 'رقم الهوية',
                      hint: 'أدخل رقم الهوية',
                      keyboardType: TextInputType.number,
                      icon: Icons.badge,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'العنوان',
                      hint: 'أدخل العنوان الكامل',
                      maxLines: 2,
                      icon: Icons.location_on,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ID Card Section
              _buildSectionTitle('بطاقة الهوية'),
              _buildCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildImagePicker(
                        label: 'الوجه الأمامي',
                        image: _idCardFrontImage,
                        imageUrl: _idCardFrontUrl,
                        onTap: () => _showImageSourceSheet(
                            (file) => setState(() => _idCardFrontImage = file)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImagePicker(
                        label: 'الوجه الخلفي',
                        image: _idCardBackImage,
                        imageUrl: _idCardBackUrl,
                        onTap: () => _showImageSourceSheet(
                            (file) => setState(() => _idCardBackImage = file)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Residence Card Section
              _buildSectionTitle('بطاقة السكن'),
              _buildCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildImagePicker(
                        label: 'الوجه الأمامي',
                        image: _residenceFrontImage,
                        imageUrl: _residenceFrontUrl,
                        onTap: () => _showImageSourceSheet((file) =>
                            setState(() => _residenceFrontImage = file)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImagePicker(
                        label: 'الوجه الخلفي',
                        image: _residenceBackImage,
                        imageUrl: _residenceBackUrl,
                        onTap: () => _showImageSourceSheet((file) =>
                            setState(() => _residenceBackImage = file)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electric,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.navy,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'جاري الحفظ...',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isEditing ? 'حفظ التعديلات' : 'إضافة العميل',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.electric,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            prefixIcon:
                Icon(icon, color: AppColors.navy.withOpacity(0.5), size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.electric, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          style: const TextStyle(
              fontFamily: 'Tajawal', fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    File? image,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    final hasImage = image != null || imageUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: hasImage ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.electric : Colors.grey[300]!,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(image,
                    fit: BoxFit.cover, width: double.infinity),
              )
            : imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl,
                        fit: BoxFit.cover, width: double.infinity),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          color: AppColors.navy.withOpacity(0.5), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
