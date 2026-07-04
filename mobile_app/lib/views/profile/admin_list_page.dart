import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'register_admin_page.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController(text: user.nama);
    String selectedRole = user.role;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Data Pengguna',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${user.email}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Role Pengguna:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin Operasional', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text('Owner (Hak Akses Penuh)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('BATAL'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSaving = true);
                            try {
                              UserModel updatedUser = UserModel(
                                uid: user.uid,
                                email: user.email,
                                nama: namaController.text.trim(),
                                role: selectedRole,
                              );
                              await _firestoreService.updateUser(updatedUser);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Data pengguna berhasil diperbarui!'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal memperbarui data: $e'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SIMPAN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (user.uid == authProvider.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menghapus akun Anda sendiri saat sedang login!'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Akun Admin?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun admin "${user.nama}" (${user.email})?\n\nAkun ini akan dihapus dari sistem gudang dan tidak akan dapat lagi masuk atau mengakses aplikasi.',
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestoreService.deleteUser(user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Akun admin "${user.nama}" berhasil dihapus.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus akun: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('HAPUS AKUN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;

    final filteredUsers = inventoryProvider.users.where((u) {
      return u.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.role.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun Admin'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: Colors.purple.withValues(alpha: 0.2))),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.purple, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Daftar pengguna yang memiliki hak akses sistem. Owner dapat menambah, mengedit data, atau menghapus admin operasional.',
                    style: TextStyle(fontSize: 13, color: Colors.purple, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari nama, email, atau role...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Users List
          Expanded(
            child: inventoryProvider.users.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Pencarian tidak menemukan pengguna.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isMe = user.uid == currentUserId;
                          final isOwner = user.isOwner;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isOwner ? Colors.amber.shade300 : Colors.purple.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isOwner
                                        ? Colors.amber.withValues(alpha: 0.2)
                                        : Colors.purple.withValues(alpha: 0.15),
                                    child: Icon(
                                      isOwner ? Icons.workspace_premium_rounded : Icons.person_rounded,
                                      color: isOwner ? Colors.amber.shade800 : Colors.purple,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Data Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                user.nama,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppTheme.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'ANDA',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isOwner
                                                ? Colors.amber.withValues(alpha: 0.2)
                                                : Colors.purple.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            user.role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isOwner ? Colors.amber.shade900 : Colors.purple.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions Button
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                        tooltip: 'Edit Pengguna',
                                        onPressed: () => _showEditUserDialog(context, user),
                                      ),
                                      if (!isMe)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                          tooltip: 'Hapus Pengguna',
                                          onPressed: () => _showDeleteConfirmDialog(context, user),
                                        )
                                      else
                                        const SizedBox(width: 12),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Tambah Admin Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterAdminPage()),
          );
        },
      ),
    );
  }
}
