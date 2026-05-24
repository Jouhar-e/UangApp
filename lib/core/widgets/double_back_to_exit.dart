import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uangapp/core/utils/app_messenger.dart';

/// Tombol kembali: jika bukan [isHome], panggil [onBackToHome].
/// Di [isHome], tekan kembali 2× dalam 2 detik untuk keluar aplikasi.
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    required this.isHome,
    this.onBackToHome,
  });

  final Widget child;
  final bool isHome;
  final VoidCallback? onBackToHome;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPress;

  @override
  void didUpdateWidget(DoubleBackToExit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isHome && widget.isHome) {
      _lastBackPress = null;
    }
  }

  void _onPopInvoked(bool didPop, dynamic result) {
    if (didPop) return;

    if (!widget.isHome) {
      widget.onBackToHome?.call();
      _lastBackPress = null;
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      showAppSnackBar(
        context,
        'Tekan kembali sekali lagi untuk keluar',
        duration: const Duration(seconds: 2),
      );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: widget.child,
    );
  }
}
