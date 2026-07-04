import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/stock_batch_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class InventoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ProductModel> _products = [];
  List<TransactionModel> _transactions = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'SEMUA';

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<TransactionModel> get transactions => _transactions;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<ProductModel> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  int get totalItems => _products.length;
  int get totalStockCount => _products.fold(0, (sum, item) => sum + item.stokTotal);

  List<String> get categories {
    Set<String> cats = {'SEMUA'};
    for (var p in _products) {
      if (p.kategori.isNotEmpty) cats.add(p.kategori);
    }
    return cats.toList();
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((p) {
      bool matchesSearch = p.namaBarang.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCategory = _selectedCategory == 'SEMUA' || p.kategori == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  InventoryProvider() {
    _listenToProducts();
    _listenToTransactions();
    _listenToUsers();
  }

  void _listenToProducts() {
    _firestoreService.getProductsStream().listen((list) {
      _products = list;
      notifyListeners();
    }, onError: (e) {
      print('Error streaming products: $e');
    });
  }

  void _listenToTransactions() {
    _firestoreService.getTransactionsStream().listen((list) {
      _transactions = list;
      notifyListeners();
    }, onError: (e) {
      print('Error streaming transactions: $e');
    });
  }

  void _listenToUsers() {
    _firestoreService.getUsersStream().listen((list) {
      _users = list;
      notifyListeners();
    }, onError: (e) {
      print('Error streaming users: $e');
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Stream<List<StockBatchModel>> getProductBatches(String productId) {
    return _firestoreService.getProductBatchesStream(productId);
  }

  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _firestoreService.addProduct(product);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _firestoreService.updateProduct(product);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteProduct(productId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> recordStockIn({
    required String productId,
    required String namaBarang,
    required int jumlah,
    required double hargaBeli,
    required String userId,
    required String namaUser,
    required String keterangan,
  }) async {
    _setLoading(true);
    try {
      await _firestoreService.recordStockIn(
        productId: productId,
        namaBarang: namaBarang,
        jumlah: jumlah,
        hargaBeli: hargaBeli,
        userId: userId,
        namaUser: namaUser,
        keterangan: keterangan,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> recordStockOut({
    required String productId,
    required String namaBarang,
    required int jumlahKeluar,
    required String userId,
    required String namaUser,
    required String keterangan,
  }) async {
    _setLoading(true);
    try {
      await _firestoreService.recordStockOut(
        productId: productId,
        namaBarang: namaBarang,
        jumlahKeluar: jumlahKeluar,
        userId: userId,
        namaUser: namaUser,
        keterangan: keterangan,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
