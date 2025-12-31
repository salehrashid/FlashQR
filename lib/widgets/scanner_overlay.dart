import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ScannerOverlayPainter(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);

    const scanBoxSize = 260.0;
    const borderRadius = 16.0;

    final center = Offset(size.width / 2, size.height / 2 - 40);

    final scanRect = Rect.fromCenter(
      center: center,
      width: scanBoxSize,
      height: scanBoxSize,
    );

    final roundedRect = RRect.fromRectAndRadius(
      scanRect,
      const Radius.circular(borderRadius),
    );

    final backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path()..addRRect(roundedRect);

    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(finalPath, overlayPaint);

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    canvas.drawRRect(roundedRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}