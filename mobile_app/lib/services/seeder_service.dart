import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class SeederService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDatabase(String userId, String namaUser) async {
    // Cek apakah sudah ada data produk
    final productsSnapshot = await _firestore.collection('products').get();
    if (productsSnapshot.docs.isNotEmpty) {
      // Jika sudah ada data, kita hapus dulu atau lewati agar tidak duplikat
      for (var doc in productsSnapshot.docs) {
        await _firestoreService.deleteProduct(doc.id);
      }
    }

    // Daftar 5 Produk Contoh Kuliner / F&B (Bakso Pentol, Tahu Gejrot, Es Krim, Cemilan, Minuman)
    final List<Map<String, dynamic>> dummyProducts = [
      {
        'nama': 'Bakso Pentol Spesial Sapi',
        'kategori': 'Frozen Food & Bakso',
        'stokMinimum': 50,
        'satuan': 'Bungkus',
        'batches': [
          {'jumlah': 100, 'harga': 18000.0, 'hariLalu': 10},
          {'jumlah': 80, 'harga': 18500.0, 'hariLalu': 5},
          {'jumlah': 50, 'harga': 19000.0, 'hariLalu': 1},
        ],
        'keluar': 70 // Simulasi keluar memotong batch pertama
      },
      {
        'nama': 'Tahu Gejrot Khas Cirebon',
        'kategori': 'Cemilan Tradisional',
        'stokMinimum': 20,
        'satuan': 'Porsi',
        'batches': [
          {'jumlah': 40, 'harga': 7500.0, 'hariLalu': 3},
          {'jumlah': 50, 'harga': 8000.0, 'hariLalu': 1},
        ],
        'keluar': 15
      },
      {
        'nama': 'Es Krim Coklat Lumer 800ml',
        'kategori': 'Es Krim & Dessert',
        'stokMinimum': 15,
        'satuan': 'Tub',
        'batches': [
          {'jumlah': 30, 'harga': 32000.0, 'hariLalu': 12},
          {'jumlah': 25, 'harga': 33500.0, 'hariLalu': 4},
        ],
        'keluar': 20
      },
      {
        'nama': 'Keripik Singkong Balado Pedas',
        'kategori': 'Cemilan Ringan',
        'stokMinimum': 30,
        'satuan': 'Pack',
        'batches': [
          {'jumlah': 60, 'harga': 9500.0, 'hariLalu': 8},
          {'jumlah': 40, 'harga': 10000.0, 'hariLalu': 2},
        ],
        'keluar': 25
      },
      {
        'nama': 'Es Teh Manis Jumbo Teh Poci',
        'kategori': 'Minuman Dingin',
        'stokMinimum': 40,
        'satuan': 'Cup',
        'batches': [
          {'jumlah': 100, 'harga': 3000.0, 'hariLalu': 5},
          {'jumlah': 100, 'harga': 3000.0, 'hariLalu': 1},
        ],
        'keluar': 45
      },
    ];

    for (var item in dummyProducts) {
      // 1. Buat produk baru
      DocumentReference prodRef = await _firestore.collection('products').add({
        'nama_barang': item['nama'],
        'kategori': item['kategori'],
        'stok_total': 0,
        'stok_minimum': item['stokMinimum'],
        'created_at': Timestamp.now(),
      });

      String prodId = prodRef.id;

      // 2. Tambahkan Batch Barang Masuk (FIFO)
      List<Map<String, dynamic>> batches = item['batches'];
      for (var b in batches) {
        int hari = b['hariLalu'];
        DateTime tglMasuk = DateTime.now().subtract(Duration(days: hari));
        
        await _firestoreService.recordStockIn(
          productId: prodId,
          namaBarang: item['nama'],
          jumlah: b['jumlah'],
          hargaBeli: b['harga'],
          userId: userId,
          namaUser: namaUser,
          keterangan: 'Stok Awal Produksi ($hari hari lalu)',
          tanggalMasuk: tglMasuk,
        );
      }

      // 3. Simulasi Barang Keluar jika ada (untuk mendemonstrasikan pemotongan FIFO)
      int jumlahKeluar = item['keluar'];
      if (jumlahKeluar > 0) {
        await _firestoreService.recordStockOut(
          productId: prodId,
          namaBarang: item['nama'],
          jumlahKeluar: jumlahKeluar,
          userId: userId,
          namaUser: namaUser,
          keterangan: 'Penjualan Hari Ini (Simulasi FIFO)',
        );
      }
    }
  }
}
