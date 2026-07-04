import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'utils/theme.dart';
import 'views/splash/splash_screen_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Catatan: Firebase belum dikonfigurasi ($e). Pastikan file google-services.json atau flutterfire configure sudah dijalankan.");
  }

  runApp(const ManajemenStokApp());
}

class ManajemenStokApp extends StatelessWidget {
  const ManajemenStokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Manajemen Stok FIFO - CV Maju Bersama',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreenPage(),
          );
        },
      ),
    );
  }
}
