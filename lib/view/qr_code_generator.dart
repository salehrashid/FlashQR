import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class QRCodeGenerator extends StatefulWidget {
  const QRCodeGenerator({super.key});

  @override
  State<QRCodeGenerator> createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  String _format = 'jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("QR Code Generator"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;

          final qrSize = maxHeight * 0.35;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: "URL",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: SizedBox(
                        width: qrSize,
                        height: qrSize,
                        child: PrettyQrView.data(
                          data:
                              _urlController.text.isEmpty
                                  ? ' '
                                  : _urlController.text,
                          decoration: const PrettyQrDecoration(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Format selector
                  DropdownButtonFormField<String>(
                    value: _format,
                    items: const [
                      DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    ],
                    onChanged: (v) => setState(() => _format = v!),
                    decoration: const InputDecoration(
                      labelText: "Output format",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _generateAndSave,
                      child: const Text("Generate & Save"),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Uint8List _convertPngToJpgWithWhiteBg(Uint8List pngBytes) {
    final pngImage = img.decodeImage(pngBytes)!;

    final whiteBg = img.Image(width: pngImage.width, height: pngImage.height);

    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(whiteBg, pngImage);

    return Uint8List.fromList(img.encodeJpg(whiteBg, quality: 100));
  }

  /// ================= CORE LOGIC =================

  Future<void> _generateAndSave() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final granted = await _requestStoragePermission();

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      return;
    }

    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await _getFlashQRDir();
      final fileName = "qr_${DateTime.now().millisecondsSinceEpoch}";
      late final String savedPath;

      if (_format == 'pdf') {
        savedPath = "${dir.path}/$fileName.pdf";

        final pdf = pw.Document();
        final imgPdf = pw.MemoryImage(pngBytes);
        pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(imgPdf))));

        await File(savedPath).writeAsBytes(await pdf.save());
      } else {
        savedPath = "${dir.path}/$fileName.jpg";

        final jpgBytes = _convertPngToJpgWithWhiteBg(pngBytes);
        await File(savedPath).writeAsBytes(jpgBytes);
      }

      await MediaScanner.loadMedia(path: savedPath);

      debugPrint("Saved at: $savedPath");

      /// save history generate
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('qr_generate_history') ?? [];
      history.insert(0, url);
      await prefs.setStringList('qr_generate_history', history);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved to Download/FlashQR")),
      );

      Navigator.pop(context, url);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  bool _isRequestingPermission = false;

  Future<bool> _requestStoragePermission() async {
    if (_isRequestingPermission) return false;
    _isRequestingPermission = true;

    try {
      if (Platform.isAndroid) {
        final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

        Permission permission;

        if (sdk >= 33) {
          // Android 13+
          permission = Permission.photos;
        } else {
          // Android 8–12
          permission = Permission.storage;
        }

        final status = await permission.request();
        return status.isGranted;
      }

      return true;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<Directory> _getFlashQRDir() async {
    final dir = Directory('/storage/emulated/0/Download/FlashQR');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
