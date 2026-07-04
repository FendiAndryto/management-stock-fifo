import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/stock_batch_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // MANAJEMEN DATA BARANG (PRODUCTS)
  // ==========================================

  Stream<List<ProductModel>> getProductsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    // Catatan: Dalam produksi nyata, bisa dicek dulu apakah masih ada stok/batch
    await _firestore.collection('products').doc(productId).delete();
  }

  // Stream daftar batch stok yang masih tersisa untuk satu produk (Berdasarkan FIFO: terlama duluan)
  Stream<List<StockBatchModel>> getProductBatchesStream(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('stock_batches')
        .orderBy('tanggal_masuk', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StockBatchModel.fromMap(doc.data(), doc.id))
          .where((batch) => batch.stokTersisa > 0)
          .toList();
    });
  }

  // ==========================================
  // TRANSAKSI BARANG MASUK (STOCK IN)
  // ==========================================

  Future<void> recordStockIn({
    required String productId,
    required String namaBarang,
    required int jumlah,
    required double hargaBeli,
    required String userId,
    required String namaUser,
    required String keterangan,
    DateTime? tanggalMasuk,
  }) async {
    final tgl = tanggalMasuk ?? DateTime.now();

    // Gunakan batch write agar penyimpanan batch, update stok, dan log transaksi terjadi atomik
    WriteBatch batch = _firestore.batch();

    // 1. Buat dokumen batch stok baru di subkoleksi
    DocumentReference batchRef = _firestore
        .collection('products')
        .doc(productId)
        .collection('stock_batches')
        .doc();
    
    batch.set(batchRef, {
      'product_id': productId,
      'stok_awal': jumlah,
      'stok_tersisa': jumlah,
      'harga_beli': hargaBeli,
      'tanggal_masuk': Timestamp.fromDate(tgl),
    });

    // 2. Update total stok produk (increment)
    DocumentReference productRef = _firestore.collection('products').doc(productId);
    batch.update(productRef, {
      'stok_total': FieldValue.increment(jumlah),
    });

    // 3. Catat riwayat transaksi
    DocumentReference txRef = _firestore.collection('transactions').doc();
    batch.set(txRef, {
      'tipe': 'MASUK',
      'product_id': productId,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'tanggal': Timestamp.fromDate(tgl),
      'user_id': userId,
      'nama_user': namaUser,
      'keterangan': keterangan,
      'fifo_details': [],
    });

    await batch.commit();
  }

  // ==========================================
  // TRANSAKSI BARANG KELUAR & FIFO (STOCK OUT)
  // ==========================================

  Future<void> recordStockOut({
    required String productId,
    required String namaBarang,
    required int jumlahKeluar,
    required String userId,
    required String namaUser,
    required String keterangan,
    DateTime? tanggalKeluar,
  }) async {
    final tgl = tanggalKeluar ?? DateTime.now();

    // Gunakan Firestore Transaction untuk memastikan tidak ada race condition saat hitung FIFO
    await _firestore.runTransaction((transaction) async {
      DocumentReference productRef = _firestore.collection('products').doc(productId);
      DocumentSnapshot productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        throw Exception("Barang tidak ditemukan dalam sistem.");
      }

      int currentTotalStock = (productSnapshot.get('stok_total') ?? 0).toInt();
      if (currentTotalStock < jumlahKeluar) {
        throw Exception("Stok tidak mencukupi! (Sisa saat ini: $currentTotalStock)");
      }

      // Ambil batch stok diurutkan dari yang paling lama (FIFO)
      QuerySnapshot batchQuery = await _firestore
          .collection('products')
          .doc(productId)
          .collection('stock_batches')
          .orderBy('tanggal_masuk', descending: false)
          .get();

      int needed = jumlahKeluar;
      List<FifoDetail> fifoDetails = [];

      for (var doc in batchQuery.docs) {
        if (needed <= 0) break;

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int available = (data['stok_tersisa'] ?? 0).toInt();
        if (available <= 0) continue;
        double hrgBeli = (data['harga_beli'] ?? 0).toDouble();

        if (available <= needed) {
          // Habiskan seluruh sisa stok di batch ini
          needed -= available;
          transaction.update(doc.reference, {'stok_tersisa': 0});
          fifoDetails.add(FifoDetail(
            batchId: doc.id,
            jumlahDiambil: available,
            hargaBeli: hrgBeli,
          ));
        } else {
          // Ambil sebagian dari batch ini sesuai kebutuhan sisa
          int sisaBaru = available - needed;
          transaction.update(doc.reference, {'stok_tersisa': sisaBaru});
          fifoDetails.add(FifoDetail(
            batchId: doc.id,
            jumlahDiambil: needed,
            hargaBeli: hrgBeli,
          ));
          needed = 0;
          break;
        }
      }

      if (needed > 0) {
        throw Exception("Gagal memotong batch FIFO. Terdapat ketidaksesuaian data stok.");
      }

      // Update stok total pada dokumen produk (decrement)
      transaction.update(productRef, {
        'stok_total': FieldValue.increment(-jumlahKeluar),
      });

      // Simpan catatan riwayat transaksi dengan rincian FIFO
      DocumentReference txRef = _firestore.collection('transactions').doc();
      transaction.set(txRef, {
        'tipe': 'KELUAR',
        'product_id': productId,
        'nama_barang': namaBarang,
        'jumlah': jumlahKeluar,
        'tanggal': Timestamp.fromDate(tgl),
        'user_id': userId,
        'nama_user': namaUser,
        'keterangan': keterangan,
        'fifo_details': fifoDetails.map((x) => x.toMap()).toList(),
      });
    });
  }

  // ==========================================
  // RIWAYAT TRANSAKSI & LAPORAN
  // ==========================================

  Stream<List<TransactionModel>> getTransactionsStream({String? filterTipe}) {
    Query query = _firestore.collection('transactions').orderBy('tanggal', descending: true);
    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      if (filterTipe != null && filterTipe.isNotEmpty && filterTipe != 'SEMUA') {
        list = list.where((tx) => tx.tipe == filterTipe).toList();
      }
      return list;
    });
  }

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').orderBy('nama', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
