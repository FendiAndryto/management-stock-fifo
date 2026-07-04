import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/product_model.dart';
import '../../models/stock_batch_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import 'product_form_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang?'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.namaBarang}"? Seluruh riwayat batch terkait akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<InventoryProvider>(context, listen: false);
              bool success = await provider.deleteProduct(product.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: AppTheme.successColor),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang & FIFO'),
        actions: authProvider.isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductFormPage(productToEdit: product)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU INFORMASI UTAMA
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.kategori,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: product.isLowStock
                                ? AppTheme.errorColor.withOpacity(0.15)
                                : AppTheme.successColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.isLowStock ? 'STOK MENIPIS' : 'STOK AMAN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: product.isLowStock ? AppTheme.errorColor : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.namaBarang,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: _buildStatColumn('Total Stok Saat Ini', '${product.stokTotal} ${product.satuan}', AppTheme.primaryColor)),
                        Expanded(child: _buildStatColumn('Stok Minimum', '${product.stokMinimum} ${product.satuan}', AppTheme.warningColor)),
                        Expanded(child: _buildStatColumn('Harga Jual', AppFormatters.currency(product.hargaJual), AppTheme.successColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // 2. RINCIAN BATCH STOK FIFO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Antrean Batch Stok (FIFO)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Tooltip(
                  message: 'Batch diurutkan dari waktu masuk paling lama (Oldest). Batch paling atas akan dipotong duluan saat barang keluar.',
                  child: Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary.withOpacity(0.7)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Daftar batch barang masuk yang saat ini masih tersedia di gudang:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),

            // STREAM BATCH STOK
            StreamBuilder<List<StockBatchModel>>(
              stream: inventoryProvider.getProductBatches(product.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                final batches = snapshot.data ?? [];

                if (batches.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.layers_clear_outlined, size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('Belum ada batch stok tersedia (Stok 0).', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: batches.length,
                  itemBuilder: (context, index) {
                    final batch = batches[index];
                    final isOldest = index == 0; // Batch pertama adalah yang akan keluar duluan menurut FIFO

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isOldest
                            ? Border.all(color: AppTheme.warningColor, width: 2)
                            : Border.all(color: Colors.transparent),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (isOldest)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              decoration: const BoxDecoration(
                                color: AppTheme.warningColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.label_important, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'DIPOTONG BERIKUTNYA (FIFO OLDEST BATCH)',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryLight.withOpacity(0.15),
                              child: Text(
                                '#${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                            title: Text(
                              'Masuk: ${AppFormatters.date(batch.tanggalMasuk)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Harga Beli: ${AppFormatters.currency(batch.hargaBeli)}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${batch.stokTersisa} ${product.satuan}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  'dari awal ${batch.stokAwal}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
