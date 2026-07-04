import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/theme.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormPage({super.key, this.productToEdit});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _kategoriController;
  late TextEditingController _satuanController;
  late TextEditingController _stokMinController;
  late TextEditingController _hargaJualController;

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.productToEdit?.namaBarang ?? '');
    _kategoriController = TextEditingController(text: widget.productToEdit?.kategori ?? 'Umum');
    _satuanController = TextEditingController(text: widget.productToEdit?.satuan ?? 'Pcs');
    _stokMinController = TextEditingController(text: '${widget.productToEdit?.stokMinimum ?? 10}');
    _hargaJualController = TextEditingController(text: '${widget.productToEdit?.hargaJual.toInt() ?? 0}');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _satuanController.dispose();
    _stokMinController.dispose();
    _hargaJualController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      
      final product = ProductModel(
        id: isEditing ? widget.productToEdit!.id : '',
        namaBarang: _namaController.text.trim(),
        kategori: _kategoriController.text.trim(),
        satuan: _satuanController.text.trim(),
        stokTotal: isEditing ? widget.productToEdit!.stokTotal : 0, // Stok awal 0, diisi via Barang Masuk
        stokMinimum: int.tryParse(_stokMinController.text) ?? 5,
        hargaJual: double.tryParse(_hargaJualController.text) ?? 0,
      );

      bool success;
      if (isEditing) {
        success = await provider.updateProduct(product);
      } else {
        success = await provider.addProduct(product);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Barang berhasil diperbarui!' : 'Barang baru berhasil ditambahkan!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      } else if (mounted && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Data Barang' : 'Tambah Barang Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner info FIFO
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryLight.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stok total tidak diinput di sini karena dihitung otomatis oleh sistem FIFO dari transaksi Barang Masuk & Keluar.',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nama Barang
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  hintText: 'Contoh: Bakso Pentol Spesial',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Nama barang harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // Kategori & Satuan (Row)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _kategoriController,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        hintText: 'Frozen Food / Cemilan',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Kategori harus diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _satuanController,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        hintText: 'Bungkus / Porsi',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Satuan harus diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Harga Jual & Stok Minimum (Row)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaJualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual (Rp)',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Harga jual harus diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stokMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas Stok Min.',
                        prefixIcon: Icon(Icons.warning_amber_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Stok minimum harus diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              ElevatedButton(
                onPressed: provider.isLoading ? null : _handleSave,
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH BARANG'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
