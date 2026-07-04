import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../products/product_list_page.dart';
import '../transactions/stock_in_page.dart';
import '../transactions/stock_out_page.dart';
import '../history/transaction_history_page.dart';
import '../reports/stock_report_page.dart';
import '../profile/profile_page.dart';
import '../profile/admin_list_page.dart';
import '../widgets/app_logo.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(
              height: 36,
              fallback: Icon(Icons.store_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CV Maju Bersama',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                  Text(
                    'Halo, ${user?.nama ?? "Pengguna"} (${user?.role.toUpperCase() ?? ""})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger refresh di provider jika diperlukan
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KARTU RINGKASAN (SUMMARY CARDS)
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Jenis Barang',
                      value: '${inventoryProvider.totalItems}',
                      subtitle: 'Item terdaftar',
                      icon: Icons.inventory_2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Stok Gudang',
                      value: '${inventoryProvider.totalStockCount}',
                      subtitle: 'Keseluruhan unit',
                      icon: Icons.stacked_bar_chart,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),

              // 2. PERINGATAN STOK MENIPIS (LOW STOCK ALERT)
              if (inventoryProvider.lowStockProducts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Peringatan Stok Menipis (${inventoryProvider.lowStockProducts.length} Barang)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: inventoryProvider.lowStockProducts.length,
                          itemBuilder: (context, index) {
                            final p = inventoryProvider.lowStockProducts[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p.namaBarang,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sisa Stok: ${p.stokTotal} ${p.satuan}',
                                    style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  Text(
                                    'Min: ${p.stokMinimum} ${p.satuan}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 20),
              ],

              // 3. MENU NAVIGASI CEPAT (QUICK ACTIONS)
              const Text(
                'Menu Operasional',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.80,
                children: [
                  _buildMenuButton(
                    context,
                    label: 'Barang Masuk',
                    icon: Icons.add_box,
                    color: AppTheme.successColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockInPage())),
                  ),
                  _buildMenuButton(
                    context,
                    label: 'Barang Keluar',
                    icon: Icons.outbox,
                    color: AppTheme.warningColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOutPage())),
                  ),
                  if (authProvider.isOwner)
                    _buildMenuButton(
                      context,
                      label: 'Data Barang',
                      icon: Icons.list_alt,
                      color: AppTheme.primaryLight,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage())),
                    ),
                  _buildMenuButton(
                    context,
                    label: 'Laporan Stok',
                    icon: Icons.assessment,
                    color: AppTheme.accentColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockReportPage())),
                  ),
                  _buildMenuButton(
                    context,
                    label: 'Riwayat Transaksi',
                    icon: Icons.history,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryPage())),
                  ),
                  if (authProvider.isOwner)
                    _buildMenuButton(
                      context,
                      label: 'Kelola Admin',
                      icon: Icons.admin_panel_settings,
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminListPage())),
                    ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),

              // 4. TRANSAKSI TERBARU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terkini',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryPage())),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (inventoryProvider.transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Belum ada riwayat transaksi.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inventoryProvider.transactions.length > 5
                      ? 5
                      : inventoryProvider.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = inventoryProvider.transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.isMasuk
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.warningColor.withOpacity(0.1),
                          child: Icon(
                            tx.isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                        ),
                        title: Text(
                          tx.namaBarang,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Oleh: ${tx.namaUser} • ${AppFormatters.date(tx.tanggal)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${tx.isMasuk ? "+" : "-"}${tx.jumlah}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: tx.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
