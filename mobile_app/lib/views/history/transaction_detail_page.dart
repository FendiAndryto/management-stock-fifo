import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/transaction_model.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: transaction.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU RINGKASAN
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: transaction.isMasuk
                          ? AppTheme.successColor.withOpacity(0.15)
                          : AppTheme.warningColor.withOpacity(0.15),
                      child: Icon(
                        transaction.isMasuk ? Icons.add_business : Icons.local_shipping,
                        size: 36,
                        color: transaction.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transaction.isMasuk ? 'TRANSAKSI MASUK' : 'TRANSAKSI KELUAR (FIFO)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: transaction.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      transaction.namaBarang,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${transaction.isMasuk ? "+" : "-"}${transaction.jumlah} Unit',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: transaction.isMasuk ? AppTheme.successColor : AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildDetailRow('Waktu Transaksi', AppFormatters.date(transaction.tanggal)),
                    const SizedBox(height: 8),
                    _buildDetailRow('Admin / Pengguna', transaction.namaUser),
                    const SizedBox(height: 8),
                    _buildDetailRow('Keterangan / Bukti', transaction.keterangan.isEmpty ? '-' : transaction.keterangan),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),

            // 2. RINCIAN PEMOTONGAN FIFO (KHUSUS TRANSAKSI KELUAR)
            if (!transaction.isMasuk) ...[
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.warningColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rincian Pemotongan Batch FIFO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Berikut adalah rincian batch stok lama yang dipotong secara otomatis oleh sistem untuk memenuhi pengeluaran ini:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              if (transaction.fifoDetails.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Tidak ada rincian batch yang tercatat.'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transaction.fifoDetails.length,
                  itemBuilder: (context, index) {
                    final detail = transaction.fifoDetails[index];
                    final totalValuasi = detail.jumlahDiambil * detail.hargaBeli;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batch ID: ${detail.batchId.length > 8 ? detail.batchId.substring(0, 8) : detail.batchId}...',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'HPP Batch: ${AppFormatters.currency(detail.hargaBeli)} / unit',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-${detail.jumlahDiambil} Unit',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.warningColor,
                                ),
                              ),
                              Text(
                                'Total HPP: ${AppFormatters.currency(totalValuasi)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                  },
                ),
            ] else ...[
              // Info untuk transaksi masuk
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppTheme.successColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transaksi masuk ini telah menciptakan batch stok baru dengan harga beli satuan yang tertera untuk persediaan FIFO.',
                        style: TextStyle(fontSize: 13, color: AppTheme.successColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
