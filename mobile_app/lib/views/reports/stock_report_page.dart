import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../widgets/export_options_modal.dart';

class StockReportPage extends StatelessWidget {
  const StockReportPage({super.key});

  void _showExportOptions(BuildContext context, InventoryProvider inv, String userName) {
    double totalValuasiJual = 0;
    for (var p in inv.allProducts) {
      totalValuasiJual += (p.stokTotal * p.hargaJual);
    }

    final exportService = ExportService();

    ExportOptionsModal.show(
      context,
      title: 'Export Laporan Stok',
      onPrintPdf: () => exportService.exportStockReportPdf(
        context: context,
        products: inv.allProducts,
        totalValuasiJual: totalValuasiJual,
        userName: userName,
        share: false,
      ),
      onSharePdf: () => exportService.exportStockReportPdf(
        context: context,
        products: inv.allProducts,
        totalValuasiJual: totalValuasiJual,
        userName: userName,
        share: true,
      ),
      onExportCsv: () => exportService.exportStockReportCsv(
        products: inv.allProducts,
        totalValuasiJual: totalValuasiJual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Hitung total estimasi nilai jual seluruh stok di gudang
    double totalValuasiJual = 0;
    for (var p in inv.allProducts) {
      totalValuasiJual += (p.stokTotal * p.hargaJual);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Stok & Valuasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Laporan Stok',
            onPressed: () => _showExportOptions(context, inv, auth.currentUser?.nama ?? 'Pengguna'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU VALUASI KESELURUHAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('ESTIMASI NILAI ASET STOK GUDANG', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold))),
                      const Icon(Icons.assessment, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppFormatters.currency(totalValuasiJual),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dari total ${inv.totalItems} jenis barang (${inv.totalStockCount} unit)',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showExportOptions(context, inv, auth.currentUser?.nama ?? 'Pengguna'),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export Laporan Stok & Valuasi (PDF / Excel)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // 2. RINCIAN PER BARANG
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rincian Stok Per Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('${inv.allProducts.length} Item', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (inv.allProducts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Text('Belum ada data barang di laporan.', style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inv.allProducts.length,
                itemBuilder: (context, index) {
                  final p = inv.allProducts[index];
                  final subtotalJual = p.stokTotal * p.hargaJual;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.namaBarang,
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
                                      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(6)),
                                      child: Text(p.kategori, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    ),
                                    Text('Harga: ${AppFormatters.currency(p.hargaJual)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${p.stokTotal} ${p.satuan}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: p.isLowStock ? AppTheme.errorColor : AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Valuasi: ${AppFormatters.currency(subtotalJual)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                },
              ),
          ],
        ),
      ),
    );
  }
}
