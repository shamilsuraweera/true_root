// Generates brand PNG assets. Run: flutter test tool/gen_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_root/core/widgets/brand_logo.dart';

Future<void> render(
  String path,
  int px, {
  required double markScale,
  bool background = true,
  bool rounded = false,
}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final size = Size.square(px.toDouble());
  if (background) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [BrandPalette.tealLight, BrandPalette.tealDeep],
      ).createShader(rect);
    if (rounded) {
      c.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(px * 0.22)), paint);
    } else {
      c.drawRect(rect, paint);
    }
  }
  final m = px * markScale;
  c.translate((px - m) / 2, (px - m) / 2);
  const BrandMarkPainter().paint(c, Size.square(m));
  final img = await rec.endRecording().toImage(px, px);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('generate icons', (tester) async {
    await tester.runAsync(() async {
      await render('assets/icon/app_icon.png', 1024, markScale: 0.66);
      await render('assets/icon/app_icon_foreground.png', 1024,
          markScale: 0.5, background: false);
      await render('web/icons/Icon-512.png', 512, markScale: 0.66);
      await render('web/icons/Icon-192.png', 192, markScale: 0.66);
      await render('web/icons/Icon-maskable-512.png', 512, markScale: 0.5);
      await render('web/icons/Icon-maskable-192.png', 192, markScale: 0.5);
      await render('web/favicon.png', 64, markScale: 0.72, rounded: true);
      await render('web/splash/img/logo.png', 512,
          markScale: 0.7, background: false);
    });
  });
}
