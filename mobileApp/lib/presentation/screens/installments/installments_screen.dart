import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InstallmentsScreen extends StatelessWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'الأقساط',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'قائمة الأقساط',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.electric,
        child: const Icon(Icons.add_card),
      ),
    );
  }
}
