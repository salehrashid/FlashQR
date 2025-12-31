import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/qr_scanner_service.dart';

class QrCodePdfPreview extends StatefulWidget {
  final String pdfPath;
  final Function(String)? onOpen;

  const QrCodePdfPreview({
    super.key,
    required this.pdfPath,
    this.onOpen,
  });

  @override
  State<QrCodePdfPreview> createState() => _QrCodePdfPreviewState();
}

class _QrCodePdfPreviewState extends State<QrCodePdfPreview> {
  String? qrValue;
  String? imagePath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _scanPdf();
  }

  Future<void> _scanPdf() async {
    try {
      final imageFile = await _extractImageFromPdf();
      final result = await QRScannerService.scanFromImage(imageFile.path);

      if (!mounted) return;

      setState(() {
        imagePath = imageFile.path;
        qrValue = result;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error scanning PDF: $e");
      if (!mounted) return;
      
      setState(() {
        loading = false;
      });
    }
  }

  Future<File> _extractImageFromPdf() async {
    final document = await PdfDocument.openFile(widget.pdfPath);
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

    return file;
  }

  bool get isUrl => QRScannerService.isUrl(qrValue);

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
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (imagePath != null) _buildImagePreview(),
        const SizedBox(height: 20),
        if (qrValue == null)
          _buildErrorText()
        else
          _buildResultSection(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Image.file(File(imagePath!), height: 260);
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
    await launchUrl(
      Uri.parse(qrValue!),
      mode: LaunchMode.externalApplication,
    );
  }
}