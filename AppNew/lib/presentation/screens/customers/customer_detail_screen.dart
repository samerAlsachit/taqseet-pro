import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/theme/app_colors.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    // In real app, load from repository
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل العميل'), actions: [
        IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.pushNamed(context, '/customers/${widget.customerId}/edit')),
        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () {}),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: AppColors.electric, child: Icon(Icons.person, size: 40, color: Colors.white)),
                  const SizedBox(height: 12),
                  const Text('اسم العميل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  const SizedBox(height: 4),
                  Text('رقم الهاتف', style: TextStyle(color: AppColors.textSecondaryLight, fontFamily: 'Tajawal')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoChip(Icons.badge, 'رقم البطاقة'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.location_on, 'العنوان'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('الصور', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _imageCard('صورة العميل', null),
                _imageCard('البطاقة وجه', null),
                _imageCard('البطاقة خلف', null),
                _imageCard('بطاقة السكن', null),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('الأقساط النشطة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('قسط #123', style: TextStyle(fontFamily: 'Tajawal')),
              subtitle: const Text('متبقي: 50,000 IQD', style: TextStyle(fontFamily: 'Tajawal')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.pushNamed(context, '/installments/123'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondaryLight),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontFamily: 'Tajawal')),
        ],
      ),
    ),
  );

  Widget _imageCard(String label, String? url) => Container(
    width: 100,
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (url != null)
          ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: url, height: 80, width: 100, fit: BoxFit.cover))
        else
          const Icon(Icons.image, color: AppColors.textSecondaryLight, size: 32),
        Text(label, style: TextStyle(fontSize: 10, fontFamily: 'Tajawal', color: AppColors.textSecondaryLight)),
      ],
    ),
  );
}
