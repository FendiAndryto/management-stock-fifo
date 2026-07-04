import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else if (uid == 'iRuCqn9YDNer3o31AJwOEwp33m02') {
        // Otomatis buat dokumen Owner utama di Firestore jika belum ada
        UserModel initialUser = UserModel(
          uid: uid,
          email: _auth.currentUser?.email ?? 'owner@cvmaju.com',
          nama: 'Owner',
          role: 'owner',
        );
        await _firestore.collection('users').doc(uid).set(initialUser.toMap());
        return initialUser;
      } else {
        // Cek apakah database masih kosong (inisialisasi awal proyek)
        QuerySnapshot allUsers = await _firestore.collection('users').limit(1).get();
        if (allUsers.docs.isEmpty) {
          UserModel initialUser = UserModel(
            uid: uid,
            email: _auth.currentUser?.email ?? 'owner@cvmaju.com',
            nama: 'Owner',
            role: 'owner',
          );
          await _firestore.collection('users').doc(uid).set(initialUser.toMap());
          return initialUser;
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Khusus Owner: Mendaftarkan akun Admin baru tanpa me-logout sesi Owner saat ini
  Future<void> registerAdminByOwner({
    required String email,
    required String password,
    required String nama,
    String role = 'admin',
  }) async {
    FirebaseApp? tempApp;
    try {
      try {
        tempApp = Firebase.app('TempAdminRegisterApp');
      } catch (_) {
        tempApp = await Firebase.initializeApp(
          name: 'TempAdminRegisterApp',
          options: Firebase.app().options,
        );
      }

      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      UserCredential credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Simpan data admin ke koleksi users di Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email.trim(),
          'nama': nama.trim(),
          'role': role,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await tempAuth.signOut();
    } catch (e) {
      rethrow;
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
    }
  }
}
