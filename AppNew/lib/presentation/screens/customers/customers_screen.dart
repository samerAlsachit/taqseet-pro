import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/customer_bloc/customer_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/empty_state.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء'), actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.pushNamed(context, '/customers/new'),
        ),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'بحث عن عميل...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => context.read<CustomerBloc>().add(LoadCustomers(search: v)),
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) return const LoadingWidget();
                if (state is CustomerError) return ErrorDisplay(message: state.message, onRetry: () => context.read<CustomerBloc>().add(LoadCustomers()));
                if (state is CustomerLoaded && state.customers.isEmpty) return const EmptyState(message: 'لا يوجد عملاء');
                if (state is CustomerLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.customers.length,
                    itemBuilder: (context, index) {
                      final c = state.customers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.electric.withValues(alpha: 0.1),
                            child: Text(c.fullName[0], style: const TextStyle(color: AppColors.electric, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.fullName, style: const TextStyle(fontFamily: 'Tajawal')),
                          subtitle: Text(c.phone ?? '', style: const TextStyle(fontFamily: 'Tajawal')),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.pushNamed(context, '/customers/${c.id}'),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
