import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import 'product_form_page.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Data Barang'),
      ),
      floatingActionButton: authProvider.isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductFormPage()),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
            )
          : null,
      body: Column(
        children: [
          // 1. SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => inventoryProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang atau kategori...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 2. KATEGORI CHIPS
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: inventoryProvider.categories.length,
                    itemBuilder: (context, index) {
                      final cat = inventoryProvider.categories[index];
                      final isSelected = inventoryProvider.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) inventoryProvider.setSelectedCategory(cat);
                          },
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: AppTheme.backgroundColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. DAFTAR BARANG
          Expanded(
            child: inventoryProvider.products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Tidak ada data barang yang sesuai.', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: inventoryProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = inventoryProvider.products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(product: product),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Icon kemasan / kategori
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: product.isLowStock
                                        ? AppTheme.errorColor.withOpacity(0.1)
                                        : AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: product.isLowStock ? AppTheme.errorColor : AppTheme.primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Info Barang
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.namaBarang,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.backgroundColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              product.kategori,
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                            ),
                                          ),
                                          Text(
                                            'Harga: ${AppFormatters.currency(product.hargaJual)}',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Badge Stok
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: product.isLowStock
                                            ? AppTheme.errorColor.withOpacity(0.15)
                                            : AppTheme.successColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${product.stokTotal} ${product.satuan}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: product.isLowStock ? AppTheme.errorColor : AppTheme.successColor,
                                        ),
                                      ),
                                    ),
                                    if (product.isLowStock)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Stok Menipis!',
                                          style: TextStyle(color: AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
