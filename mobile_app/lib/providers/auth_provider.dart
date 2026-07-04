import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _firebaseUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
        if (_currentUser == null) {
          await _authService.logout();
          _firebaseUser = null;
          _errorMessage = 'Akun Anda tidak ditemukan atau telah dihapus oleh Owner.';
        }
      } else {
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email, password);
      if (_currentUser == null) {
        await _authService.logout();
        _firebaseUser = null;
        _errorMessage = 'Akun Anda tidak ditemukan atau telah dihapus oleh Owner.';
      } else {
        _firebaseUser = FirebaseAuth.instance.currentUser;
      }
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _errorMessage = 'Email atau password salah.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'Format email tidak valid.';
      } else {
        _errorMessage = e.message ?? 'Terjadi kesalahan login.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan sistem: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _firebaseUser = null;
    notifyListeners();
  }

  Future<bool> registerAdmin({
    required String email,
    required String password,
    required String nama,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerAdminByOwner(
        email: email,
        password: password,
        nama: nama,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal mendaftarkan admin: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
