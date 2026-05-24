import 'package:flutter/material.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/widgets/app_brand_icon.dart';

/// Splash branding: gradien sesuai tema, ikon berbingkai putih, loading animasi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
    height: 1.2,
  );

  static const _subtitleStyle = TextStyle(
    color: Color(0xE6FFFFFF),
    fontSize: 14,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
    height: 1.3,
  );

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final gradientColors = palette.splashGradient;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppBrandIcon(size: 112, showBorder: true),
                  const SizedBox(height: 22),
                  const Text(
                    'UangApp',
                    textAlign: TextAlign.center,
                    style: _titleStyle,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pelacak keuangan Anda',
                    textAlign: TextAlign.center,
                    style: _subtitleStyle,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: palette.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
