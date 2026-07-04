class UserModel {
  final String uid;
  final String email;
  final String nama;
  final String role; // 'owner' atau 'admin'

  UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      nama: map['nama'] ?? 'Pengguna',
      role: map['role'] ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nama': nama,
      'role': role,
    };
  }
}
