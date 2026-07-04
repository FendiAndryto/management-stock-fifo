import 'package:cloud_firestore/cloud_firestore.dart';

class FifoDetail {
  final String batchId;
  final int jumlahDiambil;
  final double hargaBeli;

  FifoDetail({
    required this.batchId,
    required this.jumlahDiambil,
    required this.hargaBeli,
  });

  factory FifoDetail.fromMap(Map<String, dynamic> map) {
    return FifoDetail(
      batchId: map['batch_id'] ?? '',
      jumlahDiambil: (map['jumlah_diambil'] ?? 0).toInt(),
      hargaBeli: (map['harga_beli'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'batch_id': batchId,
      'jumlah_diambil': jumlahDiambil,
      'harga_beli': hargaBeli,
    };
  }
}

class TransactionModel {
  final String txId;
  final String tipe; // 'MASUK' atau 'KELUAR'
  final String productId;
  final String namaBarang;
  final int jumlah;
  final DateTime tanggal;
  final String userId;
  final String namaUser;
  final String keterangan;
  final List<FifoDetail> fifoDetails;

  TransactionModel({
    required this.txId,
    required this.tipe,
    required this.productId,
    required this.namaBarang,
    required this.jumlah,
    required this.tanggal,
    required this.userId,
    required this.namaUser,
    required this.keterangan,
    this.fifoDetails = const [],
  });

  bool get isMasuk => tipe == 'MASUK';

  factory TransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime tgl = DateTime.now();
    if (map['tanggal'] != null) {
      if (map['tanggal'] is Timestamp) {
        tgl = (map['tanggal'] as Timestamp).toDate();
      } else if (map['tanggal'] is String) {
        tgl = DateTime.tryParse(map['tanggal']) ?? DateTime.now();
      }
    }

    List<FifoDetail> details = [];
    if (map['fifo_details'] != null && map['fifo_details'] is List) {
      details = (map['fifo_details'] as List)
          .map((item) => FifoDetail.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return TransactionModel(
      txId: documentId,
      tipe: map['tipe'] ?? 'MASUK',
      productId: map['product_id'] ?? '',
      namaBarang: map['nama_barang'] ?? '',
      jumlah: (map['jumlah'] ?? 0).toInt(),
      tanggal: tgl,
      userId: map['user_id'] ?? '',
      namaUser: map['nama_user'] ?? '',
      keterangan: map['keterangan'] ?? '',
      fifoDetails: details,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipe': tipe,
      'product_id': productId,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'tanggal': Timestamp.fromDate(tanggal),
      'user_id': userId,
      'nama_user': namaUser,
      'keterangan': keterangan,
      'fifo_details': fifoDetails.map((x) => x.toMap()).toList(),
    };
  }
}
