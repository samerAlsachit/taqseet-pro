import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../customers/customers_screen.dart';
import '../products/products_screen.dart';
import '../installments/installments_screen.dart';
import '../cash_sales/cash_sale_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    CustomersScreen(),
    ProductsScreen(),
    InstallmentsScreen(),
    CashSaleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'العملاء'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الأقساط'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'بيع نقدي'),
        ],
      ),
    );
  }
}
