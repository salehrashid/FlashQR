import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner/navigator/nav_router.dart';
import 'package:url_launcher/url_launcher.dart';

class QRCodeScanner extends StatefulWidget {
  const QRCodeScanner({super.key});

  @override
  State<QRCodeScanner> createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

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

                    if (mounted) {
                      Navigator.pop(context, finalValue);
                    }
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
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          const ScannerOverlay(),

          // Hint text
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                "Arahkan QR Code ke dalam kotak",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth * 0.7;

        return Stack(
          children: [
            // Dark overlay
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                  Center(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scanner box border
            Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
