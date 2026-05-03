import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CashSalesScreen extends StatelessWidget {
  const CashSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'البيع النقدي',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.receipt_long),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'قائمة المبيعات النقدية',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.electric,
        child: const Icon(Icons.point_of_sale),
      ),
    );
  }
}
