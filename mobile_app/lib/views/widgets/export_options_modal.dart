import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class ExportOptionsModal extends StatelessWidget {
  final String title;
  final VoidCallback onPrintPdf;
  final VoidCallback onSharePdf;
  final VoidCallback onExportCsv;

  const ExportOptionsModal({
    super.key,
    required this.title,
    required this.onPrintPdf,
    required this.onSharePdf,
    required this.onExportCsv,
  });

  static void show(
    BuildContext context, {
    required String title,
    required VoidCallback onPrintPdf,
    required VoidCallback onSharePdf,
    required VoidCallback onExportCsv,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportOptionsModal(
        title: title,
        onPrintPdf: onPrintPdf,
        onSharePdf: onSharePdf,
        onExportCsv: onExportCsv,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.download_rounded, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Text(
                      'Pilih format laporan yang ingin Anda ekspor',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Opsi Print / Simpan PDF
          _buildOptionTile(
            context,
            icon: Icons.print_rounded,
            iconColor: Colors.blue,
            title: 'Cetak / Simpan PDF (Print Preview)',
            subtitle: 'Buka tampilan cetak resmi atau simpan sebagai dokumen .PDF',
            onTap: () {
              Navigator.pop(context);
              onPrintPdf();
            },
          ),
          const SizedBox(height: 12),

          // 2. Opsi Share PDF Langsung
          _buildOptionTile(
            context,
            icon: Icons.share_rounded,
            iconColor: Colors.teal,
            title: 'Bagikan Dokumen PDF',
            subtitle: 'Kirim langsung file PDF ke WhatsApp, Telegram, atau Email',
            onTap: () {
              Navigator.pop(context);
              onSharePdf();
            },
          ),
          const SizedBox(height: 12),

          // 3. Opsi Export CSV / Excel
          _buildOptionTile(
            context,
            icon: Icons.table_chart_rounded,
            iconColor: Colors.green,
            title: 'Export ke Excel (.CSV)',
            subtitle: 'Unduh tabel data untuk pembukuan akuntansi di Excel',
            onTap: () {
              Navigator.pop(context);
              onExportCsv();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.05),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
