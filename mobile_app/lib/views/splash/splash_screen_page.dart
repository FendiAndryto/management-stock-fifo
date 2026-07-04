import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../widgets/app_logo.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Tampilkan splash screen selama 2.5 detik agar animasi dan branding terlihat jelas
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Arahkan ke halaman Dashboard jika sudah login, atau ke Login Page jika belum
    final Widget nextScreen = authProvider.isAuthenticated
        ? const DashboardPage()
        : const LoginPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryColor,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Center Logo & Title
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Aplikasi
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const AppLogo(
                      height: 120,
                    ),
                  )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 600.ms, duration: 1200.ms),
                  const SizedBox(height: 24),

                  // Nama Perusahaan
                  const Text(
                    'CV MAJU BERSAMA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 8),

                  // Subjudul
                  Text(
                    'Sistem Manajemen Stok & Valuasi FIFO',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                ],
              ),
            ),

            // Footer Loading & Copyright
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 16),
                  Text(
                    'v1.0.0 • Professional Inventory System',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
