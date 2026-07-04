import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/transaction_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../widgets/date_filter_picker_modal.dart';
import '../widgets/export_options_modal.dart';
import '../widgets/user_picker_modal.dart';
import 'transaction_detail_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String _filterWaktu = 'SEMUA';
  String _filterTipe = 'SEMUA';
  String _filterUser = 'SEMUA';

  DateTime? _customDate;
  int? _customMonth;
  int? _customYear;

  List<TransactionModel> _getFilteredList(List<TransactionModel> all) {
    return all.where((tx) {
      // 1. Filter Tipe
      if (_filterTipe != 'SEMUA' && tx.tipe != _filterTipe) {
        return false;
      }

      // 2. Filter User
      if (_filterUser != 'SEMUA' && tx.userId != _filterUser && tx.namaUser != _filterUser) {
        return false;
      }

      // 3. Filter Waktu
      if (_filterWaktu != 'SEMUA') {
        final txDate = tx.tanggal;
        if (_filterWaktu == 'CUSTOM_TANGGAL' && _customDate != null) {
          if (txDate.year != _customDate!.year || txDate.month != _customDate!.month || txDate.day != _customDate!.day) {
            return false;
          }
        } else if (_filterWaktu == 'CUSTOM_BULAN' && _customMonth != null && _customYear != null) {
          if (txDate.year != _customYear || txDate.month != _customMonth) {
            return false;
          }
        } else if (_filterWaktu == 'CUSTOM_TAHUN' && _customYear != null) {
          if (txDate.year != _customYear) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  List<Map<String, String>> _getUniqueUsers(InventoryProvider inv) {
    Map<String, String> userMap = {};
    for (var u in inv.users) {
      userMap[u.uid] = '${u.nama} (${u.role.toUpperCase()})';
    }
    for (var tx in inv.transactions) {
      if (!userMap.containsKey(tx.userId)) {
        userMap[tx.userId] = tx.namaUser;
      }
    }
    List<Map<String, String>> list = [
      {'id': 'SEMUA', 'label': 'Semua User'}
    ];
    userMap.forEach((k, v) {
      list.add({'id': k, 'label': v});
    });
    return list;
  }

  String _getSelectedWaktuLabel() {
    if (_filterWaktu == 'SEMUA') return 'Semua Waktu';
    if (_filterWaktu == 'CUSTOM_TANGGAL' && _customDate != null) return '📅 Tanggal: ${AppFormatters.date(_customDate!)}';
    if (_filterWaktu == 'CUSTOM_BULAN' && _customMonth != null && _customYear != null) return '🗓️ Bulan: ${_getMonthName(_customMonth!)} $_customYear';
    if (_filterWaktu == 'CUSTOM_TAHUN' && _customYear != null) return '📅 Tahun: $_customYear';
    return 'Semua Waktu';
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  String _getSelectedUserLabel(InventoryProvider inv) {
    final list = _getUniqueUsers(inv);
    final found = list.firstWhere((u) => u['id'] == _filterUser, orElse: () => {'label': 'Semua User'});
    return found['label'] ?? 'Semua User';
  }

  void _showExportOptions(BuildContext context, List<TransactionModel> filtered, InventoryProvider inv, String userName) {
    final exportService = ExportService();
    final String periodLabel = _getSelectedWaktuLabel();
    final String userLabel = _getSelectedUserLabel(inv);

    ExportOptionsModal.show(
      context,
      title: 'Export Riwayat Transaksi',
      onPrintPdf: () => exportService.exportTransactionHistoryPdf(
        context: context,
        transactions: filtered,
        filterPeriodLabel: periodLabel,
        filterUserLabel: userLabel,
        userName: userName,
        share: false,
      ),
      onSharePdf: () => exportService.exportTransactionHistoryPdf(
        context: context,
        transactions: filtered,
        filterPeriodLabel: periodLabel,
        filterUserLabel: userLabel,
        userName: userName,
        share: true,
      ),
      onExportCsv: () => exportService.exportTransactionHistoryCsv(
        transactions: filtered,
        filterPeriodLabel: periodLabel,
        filterUserLabel: userLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final bool isOwner = auth.isOwner;
    final filtered = _getFilteredList(inv.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export Riwayat Transaksi',
              onPressed: () => _showExportOptions(context, filtered, inv, auth.currentUser?.nama ?? 'Owner'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar Panel (Waktu, Tipe, User)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Filter Periode Waktu (Modal Picker persis seperti filter user)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    const Text('Waktu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final res = await DateFilterPickerModal.show(
                            context,
                            selectedWaktu: _filterWaktu,
                            customDate: _customDate,
                            customMonth: _customMonth,
                            customYear: _customYear,
                            title: 'Pilih Filter Waktu',
                          );
                          if (res != null) {
                            setState(() {
                              _filterWaktu = res['waktu'];
                              if (_filterWaktu == 'CUSTOM_TANGGAL') {
                                _customDate = res['date'] as DateTime?;
                              } else if (_filterWaktu == 'CUSTOM_BULAN') {
                                _customMonth = res['month'] as int?;
                                _customYear = res['year'] as int?;
                              } else if (_filterWaktu == 'CUSTOM_TAHUN') {
                                _customYear = res['year'] as int?;
                              }
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _filterWaktu != 'SEMUA' ? AppTheme.primaryColor : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _filterWaktu != 'SEMUA' ? Icons.event_available : Icons.calendar_today_outlined,
                                size: 18,
                                color: _filterWaktu != 'SEMUA' ? AppTheme.primaryColor : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getSelectedWaktuLabel(),
                                  style: TextStyle(
                                    fontWeight: _filterWaktu != 'SEMUA' ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                    color: _filterWaktu != 'SEMUA' ? AppTheme.primaryColor : AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_filterWaktu != 'SEMUA')
                                InkWell(
                                  onTap: () => setState(() => _filterWaktu = 'SEMUA'),
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                                  ),
                                ),
                              const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Filter Tipe Transaksi
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.swap_vert, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      const Text('Tipe:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 14),
                      _buildChip(label: 'Semua Tipe', isSelected: _filterTipe == 'SEMUA', onTap: () => setState(() => _filterTipe = 'SEMUA')),
                      const SizedBox(width: 6),
                      _buildChip(label: 'Barang Masuk', isSelected: _filterTipe == 'MASUK', onTap: () => setState(() => _filterTipe = 'MASUK')),
                      const SizedBox(width: 6),
                      _buildChip(label: 'Barang Keluar', isSelected: _filterTipe == 'KELUAR', onTap: () => setState(() => _filterTipe = 'KELUAR')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Filter User (Kaya pilih barang di halaman keluar dan masuk barang)
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    const Text('User:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final selected = await UserPickerModal.show(
                            context,
                            _getUniqueUsers(inv),
                            selected: _filterUser,
                            title: 'Pilih Filter User',
                          );
                          if (selected != null) {
                            setState(() => _filterUser = selected);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _filterUser != 'SEMUA' ? AppTheme.primaryColor : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _filterUser != 'SEMUA' ? Icons.person : Icons.people_outline,
                                size: 18,
                                color: _filterUser != 'SEMUA' ? AppTheme.primaryColor : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getSelectedUserLabel(inv),
                                  style: TextStyle(
                                    fontWeight: _filterUser != 'SEMUA' ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                    color: _filterUser != 'SEMUA' ? AppTheme.primaryColor : AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_filterUser != 'SEMUA')
                                InkWell(
                                  onTap: () => setState(() => _filterUser = 'SEMUA'),
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                                  ),
                                ),
                              const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Daftar Transaksi
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('Belum ada riwayat transaksi.', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TransactionDetailPage(transaction: tx)),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Icon tipe
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: tx.isMasuk
                                      ? AppTheme.successColor.withValues(alpha: 0.15)
                                      : AppTheme.warningColor.withValues(alpha: 0.15),
                                  child: Icon(
                                    tx.isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: tx.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Detail TX
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.namaBarang,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tx.keterangan,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Flexible(child: Text(tx.namaUser, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(AppFormatters.date(tx.tanggal), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Jumlah
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${tx.isMasuk ? "+" : "-"}${tx.jumlah}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: tx.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                                      ),
                                    ),
                                    Text(
                                      tx.isMasuk ? 'MASUK' : 'KELUAR (FIFO)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: tx.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
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

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onTap();
        }
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}
