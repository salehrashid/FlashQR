import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrCodeGallery extends StatefulWidget {
  final String imagePath;
  final Function(String)? onOpen; // callback

  const QrCodeGallery({super.key, required this.imagePath, this.onOpen});

  @override
  State<QrCodeGallery> createState() => _QrCodeGalleryState();
}

class _QrCodeGalleryState extends State<QrCodeGallery> {
  String? qrValue;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scanQrFromImage();
  }

  Future<void> _scanQrFromImage() async {
    final controller = MobileScannerController();
    final result = await controller.analyzeImage(widget.imagePath);

    if (!mounted) return;

    setState(() {
      qrValue =
          (result != null && result.barcodes.isNotEmpty)
              ? result.barcodes.first.rawValue
              : null;
      isLoading = false;
    });
  }

  bool get isUrl =>
      qrValue != null &&
      (qrValue!.startsWith('http://') || qrValue!.startsWith('https://'));

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
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath),
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (isLoading)
              const CircularProgressIndicator()
            else if (qrValue == null)
              const Text(
                'QR code not detected',
                style: TextStyle(color: Colors.red),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Result',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(qrValue!),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: qrValue!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open'),
                          onPressed:
                              isUrl
                                  ? () async {
                                    // save to history via callback
                                    widget.onOpen?.call(qrValue!);

                                    // open link
                                    final uri = Uri.parse(qrValue!);
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
