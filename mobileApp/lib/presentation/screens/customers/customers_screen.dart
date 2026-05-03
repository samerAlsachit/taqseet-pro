import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'العملاء',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'قائمة العملاء',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.electric,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
