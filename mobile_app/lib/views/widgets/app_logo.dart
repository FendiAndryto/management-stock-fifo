import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final Widget? fallback;

  const AppLogo({
    super.key,
    this.height = 40,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Jika file logo.png belum ada di folder atau gagal dimuat,
        // tampilkan fallback widget agar aplikasi tetap cantik dan tidak crash/merah.
        return fallback ??
            Icon(
              Icons.inventory_2_rounded,
              size: height,
              color: Colors.white,
            );
      },
    );
  }
}
