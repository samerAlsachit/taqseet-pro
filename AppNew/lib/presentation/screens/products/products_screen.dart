import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product_bloc/product_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/empty_state.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المخزن'), actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.pushNamed(context, '/products/new'),
        ),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'بحث عن منتج...', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (v) => context.read<ProductBloc>().add(LoadProducts(search: v)),
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) return const LoadingWidget();
                if (state is ProductError) return ErrorDisplay(message: state.message, onRetry: () => context.read<ProductBloc>().add(LoadProducts()));
                if (state is ProductLoaded && state.products.isEmpty) return const EmptyState(message: 'لا يوجد منتجات');
                if (state is ProductLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final p = state.products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.electric.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.inventory_2, color: AppColors.electric),
                          ),
                          title: Text(p.name, style: const TextStyle(fontFamily: 'Tajawal')),
                          subtitle: Text('الكمية: ${p.quantity}', style: const TextStyle(fontFamily: 'Tajawal')),
                          trailing: Text(p.priceIqd != null ? '${p.priceIqd!.toInt()} IQD' : '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                          onTap: () => Navigator.pushNamed(context, '/products/${p.id}'),
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
