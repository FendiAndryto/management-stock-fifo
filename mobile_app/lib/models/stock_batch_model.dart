import 'package:cloud_firestore/cloud_firestore.dart';

class StockBatchModel {
  final String batchId;
  final String productId;
  final int stokAwal;
  final int stokTersisa;
  final double hargaBeli;
  final DateTime tanggalMasuk;

  StockBatchModel({
    required this.batchId,
    required this.productId,
    required this.stokAwal,
    required this.stokTersisa,
    required this.hargaBeli,
    required this.tanggalMasuk,
  });

  factory StockBatchModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime tgl = DateTime.now();
    if (map['tanggal_masuk'] != null) {
      if (map['tanggal_masuk'] is Timestamp) {
        tgl = (map['tanggal_masuk'] as Timestamp).toDate();
      } else if (map['tanggal_masuk'] is String) {
        tgl = DateTime.tryParse(map['tanggal_masuk']) ?? DateTime.now();
      }
    }

    return StockBatchModel(
      batchId: documentId,
      productId: map['product_id'] ?? '',
      stokAwal: (map['stok_awal'] ?? 0).toInt(),
      stokTersisa: (map['stok_tersisa'] ?? 0).toInt(),
      hargaBeli: (map['harga_beli'] ?? 0).toDouble(),
      tanggalMasuk: tgl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'stok_awal': stokAwal,
      'stok_tersisa': stokTersisa,
      'harga_beli': hargaBeli,
      'tanggal_masuk': Timestamp.fromDate(tanggalMasuk),
    };
  }
}
