import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

class QrPdfResultPage extends StatefulWidget {
  final String pdfPath;
  final Function(String)? onOpen;

  const QrPdfResultPage({super.key, required this.pdfPath, this.onOpen});

  @override
  State<QrPdfResultPage> createState() => _QrPdfResultPageState();
}

class _QrPdfResultPageState extends State<QrPdfResultPage> {
  String? qrValue;
  String? imagePath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _scanPdf();
  }

  Future<void> _scanPdf() async {
    final document = await PdfDocument.openFile(widget.pdfPath);

    // Ambil halaman pertama
    final page = await document.getPage(1);

    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/pdf_qr.png');

    await file.writeAsBytes(pageImage!.bytes);

    await page.close();
    await document.close();

    final controller = MobileScannerController();
    final result = await controller.analyzeImage(file.path);

    if (!mounted) return;

    setState(() {
      imagePath = file.path;
      qrValue =
          (result != null && result.barcodes.isNotEmpty)
              ? result.barcodes.first.rawValue
              : null;
      loading = false;
    });
  }

  bool get isUrl =>
      qrValue != null &&
      (qrValue!.startsWith('http://') || qrValue!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR from PDF'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    if (imagePath != null)
                      Image.file(File(imagePath!), height: 260),

                    const SizedBox(height: 20),

                    if (qrValue == null)
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
                                    Clipboard.setData(
                                      ClipboardData(text: qrValue!),
                                    );
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
                                            widget.onOpen?.call(qrValue!);
                                            await launchUrl(
                                              Uri.parse(qrValue!),
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
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
