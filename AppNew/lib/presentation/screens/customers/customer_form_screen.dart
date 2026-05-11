import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../blocs/customer_bloc/customer_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/datasources/remote/storage_api.dart';

class CustomerFormScreen extends StatefulWidget {
  final String? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneAltController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageApi();

  File? _imageFile;
  File? _idFrontFile;
  File? _idBackFile;
  File? _residenceFile;
  bool _submitting = false;

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  Future<void> _pickImage(String type) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1200, maxHeight: 1200);
    if (picked == null) return;
    final file = File(picked.path);
    final compressed = await ImageUtils.compressImage(file);
    setState(() {
      switch (type) {
        case 'image': _imageFile = compressed ?? file; break;
        case 'id_front': _idFrontFile = compressed ?? file; break;
        case 'id_back': _idBackFile = compressed ?? file; break;
        case 'residence': _residenceFile = compressed ?? file; break;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final uploads = <String, File?>{};
    if (_imageFile != null) uploads['customers/${_uuid.v4()}_image.jpg'] = _imageFile;
    if (_idFrontFile != null) uploads['customers/${_uuid.v4()}_id_front.jpg'] = _idFrontFile;
    if (_idBackFile != null) uploads['customers/${_uuid.v4()}_id_back.jpg'] = _idBackFile;
    if (_residenceFile != null) uploads['customers/${_uuid.v4()}_residence.jpg'] = _residenceFile;

    String? imageUrl;
    String? idDocUrl;
    final extraDocs = <String>[];

    for (final entry in uploads.entries) {
      final url = await _storage.uploadImage(entry.key, entry.value!);
      if (url != null) {
        if (entry.key.contains('_image.jpg')) {
          imageUrl = url;
        } else if (entry.key.contains('_id_front.jpg') || entry.key.contains('_id_back.jpg')) {
          idDocUrl ??= url;
          if (!entry.key.contains('_id_front.jpg')) {
            extraDocs.add(url);
          }
        } else {
          extraDocs.add(url);
        }
      }
    }

    if (!mounted) return;
    context.read<CustomerBloc>().add(CreateCustomer({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'phone_alt': _phoneAltController.text.trim(),
      'national_id': _nationalIdController.text.trim(),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
      'image_url': imageUrl,
      'id_doc_url': idDocUrl,
      'extra_docs': extraDocs,
    }));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phoneAltController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customerId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'تعديل عميل' : 'إضافة عميل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneAltController,
                decoration: const InputDecoration(labelText: 'هاتف إضافي', prefixIcon: Icon(Icons.phone_android)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalIdController,
                decoration: const InputDecoration(labelText: 'رقم البطاقة الوطنية', prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes)),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text('الصور', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _imagePicker('صورة العميل', _imageFile, () => _pickImage('image'))),
                  const SizedBox(width: 8),
                  Expanded(child: _imagePicker('البطاقة (وجه)', _idFrontFile, () => _pickImage('id_front'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _imagePicker('البطاقة (خلف)', _idBackFile, () => _pickImage('id_back'))),
                  const SizedBox(width: 8),
                  Expanded(child: _imagePicker('بطاقة السكن', _residenceFile, () => _pickImage('residence'))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'حفظ التعديلات' : 'إضافة العميل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePicker(String label, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
          image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: AppColors.textSecondaryLight),
                  Text(label, style: const TextStyle(fontSize: 10, fontFamily: 'Tajawal', color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
                ],
              )
            : null,
      ),
    );
  }
}
