import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/theme.dart';
import '../widgets/product_picker_modal.dart';

class StockOutPage extends StatefulWidget {
  final ProductModel? selectedProduct;

  const StockOutPage({super.key, this.selectedProduct});

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  final _formKey = GlobalKey<FormState>();
  ProductModel? _currentProduct;
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.selectedProduct;
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_currentProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih barang terlebih dahulu!'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    int jumlah = int.tryParse(_jumlahController.text) ?? 0;
    if (jumlah > _currentProduct!.stokTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak mencukupi! Sisa stok saat ini hanya ${_currentProduct!.stokTotal} ${_currentProduct!.satuan}.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final inv = Provider.of<InventoryProvider>(context, listen: false);
      final user = auth.currentUser;

      bool success = await inv.recordStockOut(
        productId: _currentProduct!.id,
        namaBarang: _currentProduct!.namaBarang,
        jumlahKeluar: jumlah,
        userId: user?.uid ?? 'admin',
        namaUser: user?.nama ?? 'Admin',
        keterangan: _keteranganController.text.trim().isEmpty ? 'Penjualan / Pengeluaran Barang' : _keteranganController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang Keluar berhasil diproses! Stok batch lama (FIFO) telah dipotong otomatis.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      } else if (mounted && inv.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(inv.errorMessage!), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Barang Keluar (FIFO Out)'),
        backgroundColor: AppTheme.warningColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Penjelasan FIFO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.5)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppTheme.warningColor, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perhitungan FIFO Otomatis Aktif',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Sistem akan memproses pengeluaran barang dengan memotong stok dari batch barang yang masuk lebih dahulu (Oldest Timestamp) secara berurutan.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pilih Barang (Searchable Modal Picker)
              const Text('Pilih Barang yang Akan Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              FormField<ProductModel>(
                initialValue: _currentProduct,
                validator: (val) => _currentProduct == null ? 'Barang harus dipilih' : null,
                builder: (formFieldState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          final selected = await ProductPickerModal.show(
                            context,
                            inv.allProducts,
                            selected: _currentProduct,
                            title: 'Pilih Barang Keluar',
                          );
                          if (selected != null) {
                            setState(() {
                              _currentProduct = selected;
                              formFieldState.didChange(selected);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: formFieldState.hasError ? AppTheme.errorColor : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.outbox_outlined,
                                color: _currentProduct != null ? AppTheme.warningColor : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _currentProduct != null
                                    ? Text(
                                        '${_currentProduct!.namaBarang} (Sisa Stok: ${_currentProduct!.stokTotal} ${_currentProduct!.satuan})',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : const Text(
                                        '--- Cari & Pilih Barang dari Gudang ---',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                              const Icon(Icons.search, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (formFieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: Text(
                            formFieldState.errorText!,
                            style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Info Sisa Stok
              if (_currentProduct != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('Total Stok Tersedia Di Gudang:', style: TextStyle(fontSize: 13))),
                      Text(
                        '${_currentProduct!.stokTotal} ${_currentProduct!.satuan}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Jumlah Keluar
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Keluar',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.numbers),
                  suffixText: _currentProduct?.satuan ?? '',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Jumlah wajib diisi';
                  int j = int.tryParse(val) ?? 0;
                  if (j <= 0) return 'Musti lebih dari 0';
                  if (_currentProduct != null && j > _currentProduct!.stokTotal) {
                    return 'Melebihi stok tersedia (${_currentProduct!.stokTotal})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Keterangan / Tujuan
              TextFormField(
                controller: _keteranganController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan / Tujuan Pengeluaran (Opsional)',
                  hintText: 'Contoh: Pengiriman ke Toko Laris No. Surat Jalan #456',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
                onPressed: inv.isLoading ? null : _handleSubmit,
                child: inv.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('PROSES BARANG KELUAR (FIFO)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
