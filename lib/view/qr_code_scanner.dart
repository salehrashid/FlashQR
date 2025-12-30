import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRCodeScanner extends StatefulWidget {
  const QRCodeScanner({super.key});

  @override
  State<QRCodeScanner> createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcode = capture.barcodes.first;
    final String? value = barcode.rawValue;

    if (value != null) {
      setState(() => _isScanned = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: const Text("QR Code Result"),
              content: Text(value),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _controller.stop();
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil("/", (route) => false);
                    }
                  },
                  child: const Text("Cancel"),
                ),

                TextButton(
                  onPressed: () async {
                    String finalValue = value.trim();

                    if (!finalValue.startsWith('http://') &&
                        !finalValue.startsWith('https://')) {
                      finalValue = 'https://$finalValue';
                    }

                    final uri = Uri.parse(finalValue);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);

                    if (!mounted) return;

                    // ❗ POP DIALOG
                    Navigator.of(context).pop();

                    // ❗ POP SCANNER PAGE + RETURN VALUE
                    Navigator.of(context, rootNavigator: true).pop(finalValue);
                  },
                  child: const Text("Open"),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("QR Code Scanner"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final scanBoxSize = screenWidth * 0.7;
          final scanBoxTop = (screenHeight - scanBoxSize) / 2;
          final torchTop = scanBoxTop + scanBoxSize + 24;

          return Stack(
            children: [
              // Camera
              MobileScanner(controller: _controller, onDetect: _onDetect),

              const ScannerOverlay(),

              Positioned(
                top: torchTop,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton(
                    iconSize: 40,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await _controller.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black54,
                  child: const Text(
                    "Point the QR Code into the box",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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

    // Ukuran scan box
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

    // Gabungkan → background MINUS hole
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(finalPath, overlayPaint);

    // Border scan box
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
