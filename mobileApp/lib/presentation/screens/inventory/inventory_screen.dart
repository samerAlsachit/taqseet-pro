import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'المخزن',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'قائمة المنتجات',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.electric,
        child: const Icon(Icons.add_box),
      ),
    );
  }
}
