import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_page.dart';
import 'admin_list_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.person_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nama ?? 'Pengguna',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: authProvider.isOwner
                    ? AppTheme.warningColor.withOpacity(0.2)
                    : AppTheme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ROLE: ${(user?.role ?? "ADMIN").toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: authProvider.isOwner ? AppTheme.warningColor : AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Card Menu
            Card(
              child: Column(
                children: [
                  if (authProvider.isOwner) ...[
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.purple),
                      title: const Text('Kelola Akun Admin'),
                      subtitle: const Text('Khusus Owner: lihat daftar, edit, hapus, atau tambah admin'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminListPage()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    title: const Text('Tentang Aplikasi'),
                    subtitle: const Text('CV Maju Bersama • Metode FIFO (v1.0.0)'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Manajemen Stok FIFO',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.inventory_2_rounded, size: 40, color: AppTheme.primaryColor),
                        children: [
                          const Text('Aplikasi mobile untuk manajemen inventaris barang gudang dengan penerapan metode First-In, First-Out (FIFO) pada CV Maju Bersama.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('KELUAR DARI AKUN (LOGOUT)'),
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
