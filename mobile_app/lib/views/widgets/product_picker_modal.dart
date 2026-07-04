import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../utils/theme.dart';

class ProductPickerModal extends StatefulWidget {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final String title;

  const ProductPickerModal({
    super.key,
    required this.products,
    this.selectedProduct,
    this.title = 'Pilih Barang',
  });

  static Future<ProductModel?> show(
    BuildContext context,
    List<ProductModel> products, {
    ProductModel? selected,
    String title = 'Pilih Barang',
  }) {
    return showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductPickerModal(
        products: products,
        selectedProduct: selected,
        title: title,
      ),
    );
  }

  @override
  State<ProductPickerModal> createState() => _ProductPickerModalState();
}

class _ProductPickerModalState extends State<ProductPickerModal> {
  String _searchQuery = '';
  String _selectedCategory = 'SEMUA';

  @override
  Widget build(BuildContext context) {
    // Collect unique categories
    List<String> categories = ['SEMUA'];
    for (var p in widget.products) {
      if (p.kategori.isNotEmpty && !categories.contains(p.kategori)) {
        categories.add(p.kategori);
      }
    }

    // Filter products
    List<ProductModel> filtered = widget.products.where((p) {
      bool matchesQuery = p.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCat = _selectedCategory == 'SEMUA' || p.kategori == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // Search Bar (Kaya search di halaman data barang)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              autofocus: false,
              onChanged: (val) => setState(() => _searchQuery = val),
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
          ),

          // Kategori Chips
          if (categories.length > 1)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: AppTheme.backgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),

          const Divider(),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Barang tidak ditemukan', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isSelected = widget.selectedProduct?.id == p.id;
                      final isLowStock = p.stokTotal <= p.stokMinimum;
                      return InkWell(
                        onTap: () => Navigator.pop(context, p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.namaBarang,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                      ),
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
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            p.kategori,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ),
                                        Text(
                                          'Stok: ${p.stokTotal} ${p.satuan}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isLowStock ? AppTheme.errorColor : AppTheme.accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                              else
                                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
