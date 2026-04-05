import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/installment.dart';
import '../../presentation/providers/installment_provider.dart';
import '../../presentation/screens/add_installment_screen.dart';
import '../../presentation/screens/installment_detail_screen.dart';
import '../../core/theme/app_theme.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load installments when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InstallmentProvider>(
        context,
        listen: false,
      ).fetchInstallments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقساط'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          // Search field
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'بحث عن قسط...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          // Status filter dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              // TODO: Implement status filter
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, color: AppColors.electric),
                    SizedBox(width: 8),
                    Text('الكل'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: AppColors.electric),
                    SizedBox(width: 8),
                    Text('نشط'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('مكتمل'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'overdue',
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('متأخر'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<InstallmentProvider>(
        builder: (context, provider, child) {
          // Navigation functions inside builder
          void navigateToDetail(Installment installment) async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstallmentDetailScreen(installment: installment),
              ),
            );
            provider.fetchInstallments();
          }

          void navigateToAddInstallment() async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddInstallmentScreen()),
            );
            provider.fetchInstallments();
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ: ${provider.error}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (provider.installments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: AppColors.electric),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أقساط حالياً',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: navigateToAddInstallment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electric,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إضافة قسط جديد'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.installments.length,
            itemBuilder: (context, index) {
              final installment = provider.installments[index];
              return _buildInstallmentCard(installment, navigateToDetail);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Get provider and navigate
          Provider.of<InstallmentProvider>(context, listen: false).fetchInstallments();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInstallmentScreen()),
          );
        },
        backgroundColor: AppColors.electric,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInstallmentCard(Installment installment, void Function(Installment) navigateToDetail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: installment.isCompleted
              ? AppColors.success
              : installment.isOverdue
                  ? AppColors.danger
                  : AppColors.electric,
          child: Icon(
            installment.isCompleted
                ? Icons.check
                : installment.isOverdue
                    ? Icons.warning
                    : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          installment.customerName?.isNotEmpty == true
              ? installment.customerName!
              : installment.productName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${installment.formattedTotalPrice} | ${installment.installmentsCount} قسط',
        ),
        trailing: Text(
          installment.statusDisplay,
          style: TextStyle(
            color: installment.isCompleted
                ? AppColors.success
                : installment.isOverdue
                    ? AppColors.danger
                    : AppColors.electric,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => navigateToDetail(installment),
      ),
    );
  }
}
