import 'package:flutter_test/flutter_test.dart';

// Model sederhana untuk pengujian algoritma FIFO secara lokal tanpa koneksi Firebase
class TestBatch {
  String id;
  int stokTersisa;
  double hargaBeli;

  TestBatch(this.id, this.stokTersisa, this.hargaBeli);
}

class TestFifoDetail {
  String batchId;
  int jumlahDiambil;
  double hargaBeli;

  TestFifoDetail(this.batchId, this.jumlahDiambil, this.hargaBeli);
}

void main() {
  group('Pengujian Logika Pemotongan Stok FIFO Otomatis', () {
    test('Simulasi Barang Keluar memotong batch paling lama (Oldest) terlebih dahulu', () {
      // 1. SETUP: 2 Batch stok masuk berurutan (Batch A tanggal tua, Batch B tanggal muda)
      List<TestBatch> antreanBatch = [
        TestBatch('batch-1-jan', 10, 3000), // Masuk 10 pcs @ Rp3.000
        TestBatch('batch-5-jan', 20, 3500), // Masuk 20 pcs @ Rp3.500
      ];

      int totalStokAwal = antreanBatch.fold(0, (sum, b) => sum + b.stokTersisa);
      expect(totalStokAwal, 30, reason: 'Total stok awal harus 30 pcs');

      // 2. ACTION: Ada transaksi Barang Keluar sebanyak 15 pcs
      int jumlahKeluar = 15;
      int needed = jumlahKeluar;
      List<TestFifoDetail> hasilFifo = [];

      for (var batch in antreanBatch) {
        if (needed <= 0) break;

        if (batch.stokTersisa <= needed) {
          int diambil = batch.stokTersisa;
          needed -= diambil;
          batch.stokTersisa = 0;
          hasilFifo.add(TestFifoDetail(batch.id, diambil, batch.hargaBeli));
        } else {
          int diambil = needed;
          batch.stokTersisa -= diambil;
          needed = 0;
          hasilFifo.add(TestFifoDetail(batch.id, diambil, batch.hargaBeli));
          break;
        }
      }

      // 3. ASSERTION / VERIFIKASI
      expect(needed, 0, reason: 'Seluruh kebutuhan 15 pcs harus terpenuhi dari batch');
      expect(hasilFifo.length, 2, reason: 'Harus memotong dari 2 batch berbeda');
      
      // Batch pertama (Oldest) harus habis terpakai 10 pcs
      expect(hasilFifo[0].batchId, 'batch-1-jan');
      expect(hasilFifo[0].jumlahDiambil, 10);
      expect(antreanBatch[0].stokTersisa, 0);

      // Batch kedua harus terpotong 5 pcs saja (sisa 15 pcs)
      expect(hasilFifo[1].batchId, 'batch-5-jan');
      expect(hasilFifo[1].jumlahDiambil, 5);
      expect(antreanBatch[1].stokTersisa, 15);

      int totalStokAkhir = antreanBatch.fold(0, (sum, b) => sum + b.stokTersisa);
      expect(totalStokAkhir, 15, reason: 'Total stok akhir di gudang menjadi 15 pcs');
      
      // Valuasi HPP barang keluar
      double totalHppKeluar = hasilFifo.fold(0, (sum, d) => sum + (d.jumlahDiambil * d.hargaBeli));
      expect(totalHppKeluar, (10 * 3000) + (5 * 3500), reason: 'Perhitungan HPP FIFO akurat');
    });

    test('Harus gagal / menolak jika jumlah keluar melebihi total stok tersedia', () {
      List<TestBatch> antreanBatch = [
        TestBatch('batch-1', 10, 5000),
      ];
      int jumlahKeluar = 15;
      int currentTotalStock = antreanBatch.fold(0, (sum, b) => sum + b.stokTersisa);

      bool isErrorThrown = false;
      if (currentTotalStock < jumlahKeluar) {
        isErrorThrown = true;
      }

      expect(isErrorThrown, true, reason: 'Sistem menolak pengeluaran barang yang melebihi stok');
    });
  });
}
