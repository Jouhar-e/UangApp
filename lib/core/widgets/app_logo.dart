import 'package:flutter/material.dart';
import 'package:uangapp/core/theme/app_palette.dart';

/// Logo UangApp: huruf U di shield (warna mengikuti tema).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: palette.forest,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: palette.forest.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.55,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: size * 0.25),
        Text(
          'UangApp',
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            color: palette.charcoal,
          ),
        ),
      ],
    );
  }
}
