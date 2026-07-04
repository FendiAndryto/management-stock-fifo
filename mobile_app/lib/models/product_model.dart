class ProductModel {
  final String id;
  final String namaBarang;
  final String kategori;
  final String satuan;
  final int stokTotal;
  final int stokMinimum;
  final double hargaJual;

  ProductModel({
    required this.id,
    required this.namaBarang,
    required this.kategori,
    required this.satuan,
    required this.stokTotal,
    required this.stokMinimum,
    required this.hargaJual,
  });

  bool get isLowStock => stokTotal <= stokMinimum;

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      namaBarang: map['nama_barang'] ?? '',
      kategori: map['kategori'] ?? 'Umum',
      satuan: map['satuan'] ?? 'Pcs',
      stokTotal: (map['stok_total'] ?? 0).toInt(),
      stokMinimum: (map['stok_minimum'] ?? 5).toInt(),
      hargaJual: (map['harga_jual'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_barang': namaBarang,
      'kategori': kategori,
      'satuan': satuan,
      'stok_total': stokTotal,
      'stok_minimum': stokMinimum,
      'harga_jual': hargaJual,
    };
  }

  ProductModel copyWith({
    String? id,
    String? namaBarang,
    String? kategori,
    String? satuan,
    int? stokTotal,
    int? stokMinimum,
    double? hargaJual,
  }) {
    return ProductModel(
      id: id ?? this.id,
      namaBarang: namaBarang ?? this.namaBarang,
      kategori: kategori ?? this.kategori,
      satuan: satuan ?? this.satuan,
      stokTotal: stokTotal ?? this.stokTotal,
      stokMinimum: stokMinimum ?? this.stokMinimum,
      hargaJual: hargaJual ?? this.hargaJual,
    );
  }
}
