import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/scanner_overlay.dart';
import '../services/qr_scanner_service.dart';

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
      _showResultDialog(value);
    }
  }

  void _showResultDialog(String value) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildResultDialog(value),
    );
  }

  Widget _buildResultDialog(String value) {
    return AlertDialog(
      title: const Text("QR Code Result"),
      content: Text(value),
      actions: [
        TextButton(
          onPressed: _handleCancel,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => _handleOpen(value),
          child: const Text("Open"),
        ),
      ],
    );
  }

  Future<void> _handleCancel() async {
    await _controller.stop();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
    }
  }

  Future<void> _handleOpen(String value) async {
    final formattedUrl = QRScannerService.formatUrl(value);
    final uri = Uri.parse(formattedUrl);
    
    await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    Navigator.of(context).pop(); // Close dialog
    Navigator.of(context, rootNavigator: true).pop(formattedUrl); // Close scanner
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
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
              MobileScanner(controller: _controller, onDetect: _onDetect),
              const ScannerOverlay(),
              _buildTorchButton(torchTop),
              _buildBottomText(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTorchButton(double top) {
    return Positioned(
      top: top,
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
          onPressed: _toggleTorch,
        ),
      ),
    );
  }

  Widget _buildBottomText() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black54,
        child: const Text(
          "Point the QR Code into the box",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}