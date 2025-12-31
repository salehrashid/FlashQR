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
  final _nameController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();

  String _format = 'jpg';
  String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  bool _initialized = false;
  int? editIndex;
  bool get isEditMode => editIndex != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      editIndex = args["index"];
      _nameController.text = args["name"] ?? '';
      _urlController.text = args["url"] ?? '';
    }

    _initialized = true;
  }

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

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "QR Name",
                      hintText: "E.g: QR Code 1",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                      child: Text(
                        isEditMode ? "Update & Save" : "Generate & Save",
                      ),
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
    final qrName = _nameController.text.trim();

    if (url.isEmpty || qrName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Name and URL are required fields")),
      );
      return;
    }

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
      final qrGenerateHistoryKey = "qr_generate_history";

      final dir = await _getFlashQRDir();

      final safeName = _sanitizeFileName(qrName);

      late final String savedPath;

      if (_format == 'pdf') {
        savedPath = "${dir.path}/$safeName.pdf";

        final pdf = pw.Document();
        final imgPdf = pw.MemoryImage(pngBytes);

        pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(imgPdf))));

        await File(savedPath).writeAsBytes(await pdf.save());
      } else {
        savedPath = "${dir.path}/$safeName.jpg";

        final jpgBytes = _convertPngToJpgWithWhiteBg(pngBytes);
        await File(savedPath).writeAsBytes(jpgBytes);
      }

      await MediaScanner.loadMedia(path: savedPath);

      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(qrGenerateHistoryKey) ?? [];

      final value = "$qrName • $url";

      if (isEditMode) {
        // update
        if (editIndex! < history.length) {
          history[editIndex!] = value;
        }
      } else {
        // create
        history.insert(0, value);
      }

      await prefs.setStringList(qrGenerateHistoryKey, history);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved to Download/FlashQR")),
      );

      Navigator.pop(context, {"name": qrName, "url": url});
    } catch (e, s) {
      debugPrint("Error: $e");
      debugPrintStack(stackTrace: s);
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
