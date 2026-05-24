import 'dart:io';

import 'package:image/image.dart' as img;

/// Forest green #5B8266 — sama dengan AppColors.forest di dashboard.
final _forest = img.ColorRgb8(91, 130, 102);
final _white = img.ColorRgb8(255, 255, 255);
const _size = 1024;

/// Huruf U putih tebal (mirip logo di AppBar dashboard).
void _drawBoldU(img.Image canvas, int x0, int y0, int x1, int y1, img.Color color) {
  final t = ((x1 - x0) * 0.26).round();
  img.fillRect(canvas, x1: x0, y1: y0, x2: x0 + t, y2: y1 - t, color: color);
  img.fillRect(canvas, x1: x1 - t, y1: y0, x2: x1, y2: y1 - t, color: color);
  img.fillRect(canvas, x1: x0, y1: y1 - t * 2, x2: x1, y2: y1, color: color);
  final cx = (x0 + x1) ~/ 2;
  final cy = y1 - t;
  final r = ((x1 - x0) ~/ 2) - 2;
  img.fillCircle(canvas, x: cx, y: cy, radius: r, color: color);
}

void _fillRoundedRect(
  img.Image canvas, {
  required int x,
  required int y,
  required int w,
  required int h,
  required int radius,
  required img.Color color,
}) {
  img.fillRect(canvas, x1: x + radius, y1: y, x2: x + w - radius, y2: y + h, color: color);
  img.fillRect(canvas, x1: x, y1: y + radius, x2: x + w, y2: y + h - radius, color: color);
  img.fillCircle(canvas, x: x + radius, y: y + radius, radius: radius, color: color);
  img.fillCircle(canvas, x: x + w - radius, y: y + radius, radius: radius, color: color);
  img.fillCircle(canvas, x: x + radius, y: y + h - radius, radius: radius, color: color);
  img.fillCircle(
    canvas,
    x: x + w - radius,
    y: y + h - radius,
    radius: radius,
    color: color,
  );
}

void main() {
  final outDir = Directory('assets/branding');
  outDir.createSync(recursive: true);

  final badgeSize = (_size * 0.72).round();
  final badgeX = (_size - badgeSize) ~/ 2;
  final badgeY = (_size - badgeSize) ~/ 2;
  final radius = (badgeSize * 0.28).round();

  final uMargin = (badgeSize * 0.22).round();
  final ux0 = badgeX + uMargin;
  final uy0 = badgeY + uMargin;
  final ux1 = badgeX + badgeSize - uMargin;
  final uy1 = badgeY + badgeSize - uMargin;

  final icon = img.Image(width: _size, height: _size);
  img.fill(icon, color: _white);
  _fillRoundedRect(
    icon,
    x: badgeX,
    y: badgeY,
    w: badgeSize,
    h: badgeSize,
    radius: radius,
    color: _forest,
  );
  _drawBoldU(icon, ux0, uy0, ux1, uy1, _white);
  File('assets/branding/app_icon.png').writeAsBytesSync(img.encodePng(icon));

  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  _fillRoundedRect(
    fg,
    x: badgeX,
    y: badgeY,
    w: badgeSize,
    h: badgeSize,
    radius: radius,
    color: _forest,
  );
  _drawBoldU(fg, ux0, uy0, ux1, uy1, _white);
  File('assets/branding/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('Icons (dashboard-style U badge) written to assets/branding/');
}
