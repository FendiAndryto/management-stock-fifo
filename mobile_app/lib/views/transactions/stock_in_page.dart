import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/theme.dart';
import '../widgets/product_picker_modal.dart';

class StockInPage extends StatefulWidget {
  final ProductModel? selectedProduct;

  const StockInPage({super.key, this.selectedProduct});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  final _formKey = GlobalKey<FormState>();
  ProductModel? _currentProduct;
  final _jumlahController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.selectedProduct;
    if (_currentProduct != null) {
      _hargaBeliController.text = '${(_currentProduct!.hargaJual * 0.8).toInt()}'; // Estimasi default harga beli 80% dari harga jual
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _hargaBeliController.dispose();
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

    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final inv = Provider.of<InventoryProvider>(context, listen: false);
      final user = auth.currentUser;

      int jumlah = int.tryParse(_jumlahController.text) ?? 0;
      double hargaBeli = double.tryParse(_hargaBeliController.text) ?? 0;

      bool success = await inv.recordStockIn(
        productId: _currentProduct!.id,
        namaBarang: _currentProduct!.namaBarang,
        jumlah: jumlah,
        hargaBeli: hargaBeli,
        userId: user?.uid ?? 'admin',
        namaUser: user?.nama ?? 'Admin',
        keterangan: _keteranganController.text.trim().isEmpty ? 'Stok Masuk dari Supplier' : _keteranganController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Barang Masuk berhasil disimpan! Batch baru FIFO telah dibuat.'),
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
        title: const Text('Input Barang Masuk (Stock In)'),
        backgroundColor: AppTheme.successColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppTheme.successColor, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Setiap barang masuk akan tercatat sebagai Batch Stok Baru dengan Timestamp untuk perhitungan metode FIFO.',
                        style: TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pilih Barang (Searchable Modal Picker)
              const Text('Pilih Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            title: 'Pilih Barang Masuk',
                          );
                          if (selected != null) {
                            setState(() {
                              _currentProduct = selected;
                              formFieldState.didChange(selected);
                              if (_hargaBeliController.text.isEmpty) {
                                _hargaBeliController.text = '${(_currentProduct!.hargaJual * 0.8).toInt()}';
                              }
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
                                Icons.inventory_2_outlined,
                                color: _currentProduct != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _currentProduct != null
                                    ? Text(
                                        '${_currentProduct!.namaBarang} (Stok: ${_currentProduct!.stokTotal} ${_currentProduct!.satuan})',
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
              const SizedBox(height: 20),

              // Jumlah Masuk & Satuan (Row)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _jumlahController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Masuk',
                        hintText: '0',
                        prefixIcon: const Icon(Icons.numbers),
                        suffixText: _currentProduct?.satuan ?? '',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Jumlah wajib diisi';
                        if ((int.tryParse(val) ?? 0) <= 0) return 'Musti lebih dari 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _hargaBeliController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Beli/Satuan (Rp)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Harga beli wajib diisi';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Keterangan / Supplier
              TextFormField(
                controller: _keteranganController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan / Supplier (Opsional)',
                  hintText: 'Contoh: Pembelian dari PT Supplier Jaya No. Faktur #123',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                onPressed: inv.isLoading ? null : _handleSubmit,
                child: inv.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SIMPAN TRANSAKSI MASUK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
