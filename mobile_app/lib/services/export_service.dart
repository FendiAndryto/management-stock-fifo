import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class ExportService {
  // ---------------------------------------------------------------------------
  // 1. EXPORT LAPORAN STOK & VALUASI FIFO (PDF)
  // ---------------------------------------------------------------------------
  Future<void> exportStockReportPdf({
    required BuildContext context,
    required List<ProductModel> products,
    required double totalValuasiJual,
    required String userName,
    bool share = false,
    String? reportTitle,
  }) async {
    final logoImage = await _loadLogoImage();
    final doc = pw.Document();

    int totalItems = products.length;
    int totalUnits = products.fold(0, (sum, p) => sum + p.stokTotal);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            // Header Kop Surat
            _buildPdfHeader(reportTitle ?? 'LAPORAN POSISI STOK & VALUASI ASET', logoImage: logoImage),
            pw.SizedBox(height: 16),
            
            // Ringkasan Eksekutif Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                border: pw.Border.all(color: PdfColors.teal),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCol('Total Jenis Barang', '$totalItems Item'),
                  _buildSummaryCol('Total Unit Gudang', '$totalUnits Unit'),
                  _buildSummaryCol('Total Nilai Aset Stok', AppFormatters.currency(totalValuasiJual), isBold: true, color: PdfColors.teal800),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Data Barang
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              headerHeight: 28,
              cellHeight: 24,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
              },
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['No', 'Kategori', 'Nama Barang', 'Stok', 'Status', 'Valuasi Aset'],
              data: List<List<String>>.generate(products.length, (index) {
                final p = products[index];
                double valuasiItem = p.stokTotal * p.hargaJual;
                String status = p.stokTotal == 0
                    ? 'Habis'
                    : (p.stokTotal <= p.stokMinimum ? 'Menipis' : 'Aman');
                return [
                  '${index + 1}',
                  p.kategori,
                  p.namaBarang,
                  '${p.stokTotal} ${p.satuan}',
                  status,
                  AppFormatters.currency(valuasiItem),
                ];
              }),
            ),
            pw.SizedBox(height: 30),

            // Footer / Tanda Tangan
            _buildPdfFooter(userName),
          ];
        },
      ),
    );

    final String prefix = (reportTitle != null && reportTitle.contains('MENIPIS')) ? 'Laporan_Stok_Menipis_' : 'Laporan_Stok_';
    final String filename = '$prefix${DateTime.now().millisecondsSinceEpoch}.pdf';
    if (share) {
      await Printing.sharePdf(bytes: await doc.save(), filename: filename);
    } else {
      await Printing.layoutPdf(onLayout: (format) async => await doc.save(), name: (reportTitle != null && reportTitle.contains('MENIPIS')) ? 'Laporan_Stok_Menipis' : 'Laporan_Stok');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. EXPORT LAPORAN STOK & VALUASI FIFO (CSV)
  // ---------------------------------------------------------------------------
  Future<void> exportStockReportCsv({
    required List<ProductModel> products,
    required double totalValuasiJual,
    String? reportTitle,
  }) async {
    final StringBuffer csv = StringBuffer();
    if (reportTitle != null) {
      csv.writeln('"$reportTitle"');
      csv.writeln('');
    }
    csv.writeln('No,Kategori,Nama Barang,Stok Total,Satuan,Stok Minimum,Status Stok,Valuasi Aset Stok');

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      double valuasiItem = p.stokTotal * p.hargaJual;
      String status = p.stokTotal == 0 ? 'Habis' : (p.stokTotal <= p.stokMinimum ? 'Menipis' : 'Aman');

      // Bersihkan teks agar format CSV aman dari koma
      String nama = '"${p.namaBarang.replaceAll('"', '""')}"';
      String kategori = '"${p.kategori.replaceAll('"', '""')}"';

      csv.writeln('${i + 1},$kategori,$nama,${p.stokTotal},${p.satuan},${p.stokMinimum},$status,$valuasiItem');
    }

    csv.writeln('');
    csv.writeln(',,,,,,,TOTAL VALUASI ASET:,$totalValuasiJual');

    final String prefix = (reportTitle != null && reportTitle.contains('MENIPIS')) ? 'Laporan_Stok_Menipis_' : 'Laporan_Stok_';
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csv.toString()));
    await Printing.sharePdf(bytes: bytes, filename: '$prefix${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  // ---------------------------------------------------------------------------
  // 3. EXPORT LAPORAN RIWAYAT TRANSAKSI (PDF)
  // ---------------------------------------------------------------------------
  Future<void> exportTransactionHistoryPdf({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required String filterPeriodLabel,
    required String filterUserLabel,
    required String userName,
    bool share = false,
  }) async {
    final logoImage = await _loadLogoImage();
    final doc = pw.Document();

    int totalMasuk = transactions.where((t) => t.isMasuk).fold(0, (sum, t) => sum + t.jumlah);
    int totalKeluar = transactions.where((t) => !t.isMasuk).fold(0, (sum, t) => sum + t.jumlah);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            // Header Kop Surat
            _buildPdfHeader('LAPORAN MUTASI & RIWAYAT TRANSAKSI STOK', logoImage: logoImage),
            pw.SizedBox(height: 8),
            pw.Text(
              'Periode: $filterPeriodLabel | User: $filterUserLabel',
              style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),

            // Ringkasan Arus
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCol('Total Transaksi', '${transactions.length} Aktivitas'),
                  _buildSummaryCol('Total Stok Masuk (+)', '$totalMasuk Unit', color: PdfColors.green700),
                  _buildSummaryCol('Total Stok Keluar (-)', '$totalKeluar Unit', color: PdfColors.orange700),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
              headerHeight: 28,
              cellHeight: 24,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
              },
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: ['Waktu', 'Tipe', 'Nama Barang', 'Jumlah', 'Keterangan', 'User'],
              data: List<List<String>>.generate(transactions.length, (index) {
                final tx = transactions[index];
                return [
                  AppFormatters.date(tx.tanggal),
                  tx.isMasuk ? 'MASUK (+)' : 'KELUAR (-)',
                  tx.namaBarang,
                  '${tx.jumlah} Unit',
                  tx.keterangan.isEmpty ? '-' : tx.keterangan,
                  tx.namaUser,
                ];
              }),
            ),
            pw.SizedBox(height: 30),

            // Footer
            _buildPdfFooter(userName),
          ];
        },
      ),
    );

    final String filename = 'Laporan_Transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf';
    if (share) {
      await Printing.sharePdf(bytes: await doc.save(), filename: filename);
    } else {
      await Printing.layoutPdf(onLayout: (format) async => await doc.save(), name: 'Laporan_Transaksi');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. EXPORT LAPORAN RIWAYAT TRANSAKSI (CSV)
  // ---------------------------------------------------------------------------
  Future<void> exportTransactionHistoryCsv({
    required List<TransactionModel> transactions,
    required String filterPeriodLabel,
    required String filterUserLabel,
  }) async {
    final StringBuffer csv = StringBuffer();
    csv.writeln('# LAPORAN MUTASI & RIWAYAT TRANSAKSI STOK');
    csv.writeln('# Periode: "${filterPeriodLabel.replaceAll('"', '""')}", User: "${filterUserLabel.replaceAll('"', '""')}"');
    csv.writeln('');
    csv.writeln('No,Waktu Transaksi,Tipe Transaksi,Nama Barang,Jumlah Unit,Keterangan / Tujuan,User / Pencatat');

    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      String tipe = tx.isMasuk ? 'MASUK (+)' : 'KELUAR (-)';
      String nama = '"${tx.namaBarang.replaceAll('"', '""')}"';
      String ket = '"${tx.keterangan.replaceAll('"', '""')}"';
      String user = '"${tx.namaUser.replaceAll('"', '""')}"';

      csv.writeln('${i + 1},"${AppFormatters.date(tx.tanggal)}",$tipe,$nama,${tx.jumlah},$ket,$user');
    }

    final Uint8List bytes = Uint8List.fromList(utf8.encode(csv.toString()));
    await Printing.sharePdf(bytes: bytes, filename: 'Laporan_Transaksi_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 4. MEMUAT LOGO DARI ASSET UNTUK KOP SURAT
  // ---------------------------------------------------------------------------
  Future<pw.ImageProvider?> _loadLogoImage() async {
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // Jika file logo.png belum ada atau gagal dimuat, abaikan (return null)
      return null;
    }
  }

  // INTERNAL HELPER WIDGETS UNTUK PDF
  // ---------------------------------------------------------------------------
  pw.Widget _buildPdfHeader(String title, {pw.ImageProvider? logoImage}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                if (logoImage != null) ...[
                  pw.Image(logoImage, width: 44, height: 44),
                  pw.SizedBox(width: 14),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CV MAJU BERSAMA', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.Text('Sistem Manajemen Stok & Valuasi FIFO', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('TANGGAL CETAK / EKSPOR', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.Text(AppFormatters.date(DateTime.now()), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.teal800, thickness: 2),
        pw.SizedBox(height: 8),
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildSummaryCol(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter(String userName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Dibuat & Diekspor Oleh:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(userName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Role: Manajemen / Operasional', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              pw.Text('Tanda Tangan & Cap', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.SizedBox(height: 24),
              pw.Text('(                                     )', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }
}
