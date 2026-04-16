import 'package:flutter/material.dart';
import '../controllers/products_controller.dart';
import '../models/product_model.dart';

/// شاشة المنتجات - Products Screen
/// تعرض قائمة المنتجات مع إمكانية البحث والتحديث
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductsController _controller = ProductsController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _loadProducts();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    await _controller.loadProducts();
  }

  Future<void> _refreshProducts() async {
    await _controller.refreshProducts();
  }

  List<ProductModel> get _filteredProducts {
    return _controller.filterProducts(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'المخزن',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Sync button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _controller.isLoading ? null : _refreshProducts,
                tooltip: 'تحديث من الخادم',
              ),
              if (_controller.isLoading)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _refreshProducts, child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        heroTag: 'products_fab',
        onPressed: () {
          Navigator.pushNamed(context, '/add-product');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    // Show loading on initial load
    if (_controller.isLoading && _controller.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل المنتجات...',
              style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // Show error if any
    if (_controller.errorMessage.isNotEmpty && _controller.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _controller.errorMessage,
              style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_controller.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد منتجات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.sync),
              label: const Text('تحديث المخزن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Show products list
    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),

        // Stats Summary
        _buildStatsSummary(),

        // Products List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'البحث في المنتجات...',
          hintStyle: const TextStyle(
            fontFamily: 'Tajawal',
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final lowStockCount = _controller.lowStockCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'إجمالي المنتجات',
            _controller.products.length.toString(),
            Icons.inventory_2_outlined,
          ),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildStatItem(
            'مخزون منخفض',
            lowStockCount.toString(),
            Icons.warning_amber_outlined,
            isWarning: lowStockCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: isWarning ? Colors.orange : Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.orange : Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2, color: Color(0xFF1E3A8A)),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'الكمية: ${product.quantity}',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: product.isLowStock ? Colors.orange : Colors.grey,
                fontWeight: product.isLowStock
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Price display
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Show both prices if available, or the main currency
                if (product.sellPriceCashIqd > 0)
                  Text(
                    '${_formatNumber(product.sellPriceCashIqd.toInt())} د.ع',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                if (product.sellPriceCashUsd > 0)
                  Text(
                    '\$${product.sellPriceCashUsd.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: product.sellPriceCashIqd > 0
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: product.sellPriceCashIqd > 0 ? 12 : 14,
                      color: product.sellPriceCashIqd > 0
                          ? Colors.grey
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                if (product.isLowStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'منخفض',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            // Popup menu for actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) => _handleProductAction(value, product),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text(
                        'تعديل المنتج',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'حذف المنتج',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to product details
        },
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Future<void> _handleProductAction(String action, ProductModel product) async {
    switch (action) {
      case 'edit':
        // Navigate to edit product
        Navigator.pushNamed(context, '/add-product', arguments: product);
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmation(product);
        if (confirmed) {
          final success = await _controller.deleteProduct(product.id);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تم حذف المنتج بنجاح',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'فشل حذف المنتج',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }

  Future<bool> _showDeleteConfirmation(ProductModel product) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'تأكيد الحذف',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'هل تريد حذف المنتج "${product.name}"؟',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'حذف',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
