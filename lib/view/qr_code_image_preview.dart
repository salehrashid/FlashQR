import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/qr_scanner_service.dart';

class QrCodeImagePreview extends StatefulWidget {
  final String imagePath;
  final Function(String)? onOpen;

  const QrCodeImagePreview({
    super.key,
    required this.imagePath,
    this.onOpen,
  });

  @override
  State<QrCodeImagePreview> createState() => _QrCodeImagePreviewState();
}

class _QrCodeImagePreviewState extends State<QrCodeImagePreview> {
  String? qrValue;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scanQrFromImage();
  }

  Future<void> _scanQrFromImage() async {
    final result = await QRScannerService.scanFromImage(widget.imagePath);

    if (!mounted) return;

    setState(() {
      qrValue = result;
      isLoading = false;
    });
  }

  bool get isUrl => QRScannerService.isUrl(qrValue);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Result'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 24),
            if (isLoading)
              const CircularProgressIndicator()
            else if (qrValue == null)
              _buildErrorText()
            else
              _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.imagePath),
          height: 260,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildErrorText() {
    return const Text(
      'QR code not detected',
      style: TextStyle(color: Colors.red),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QR Result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SelectableText(qrValue!),
        const SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: _handleCopy,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open'),
            onPressed: isUrl ? _handleOpen : null,
          ),
        ),
      ],
    );
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: qrValue!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _handleOpen() async {
    widget.onOpen?.call(qrValue!);

    final uri = Uri.parse(qrValue!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}