import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../services/permission_service.dart';
import '../services/qr_generator_service.dart';
import '../services/storage_service.dart';
import '../models/qr_item.dart';

class QRCodeGenerator extends StatefulWidget {
  const QRCodeGenerator({super.key});

  @override
  State<QRCodeGenerator> createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();

  String _format = 'jpg';
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
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUrlField(),
                  const SizedBox(height: 16),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildQRPreview(constraints.maxHeight * 0.35),
                  const SizedBox(height: 16),
                  _buildFormatSelector(),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUrlField() {
    return TextField(
      controller: _urlController,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: "URL",
        border: OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: "QR Name",
        hintText: "E.g: QR Code 1",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildQRPreview(double qrSize) {
    return Center(
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
                  _urlController.text.isEmpty ? ' ' : _urlController.text,
              decoration: const PrettyQrDecoration(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _generateAndSave,
        child: Text(isEditMode ? "Update & Save" : "Generate & Save"),
      ),
    );
  }

  // ========== CORE LOGIC ==========

  Future<void> _generateAndSave() async {
    final url = _urlController.text.trim();
    final qrName = _nameController.text.trim();

    if (!_validateInputs(url, qrName)) return;

    final granted = await PermissionService.requestStoragePermission();
    if (!granted) {
      _showMessage("Storage permission denied");
      return;
    }

    try {
      final pngBytes = await _captureQRImage();
      await _saveQRCode(pngBytes, qrName);
      await _updateHistory(qrName, url);

      if (!mounted) return;

      _showMessage("Saved to Download/FlashQR");
      Navigator.pop(context, {"name": qrName, "url": url});
    } catch (e, s) {
      debugPrint("Error: $e");
      debugPrintStack(stackTrace: s);
      _showMessage("Failed to save QR code");
    }
  }

  bool _validateInputs(String url, String qrName) {
    if (url.isEmpty || qrName.isEmpty) {
      _showMessage("QR Name and URL are required fields");
      return false;
    }
    return true;
  }

  Future<Uint8List> _captureQRImage() async {
    final boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveQRCode(Uint8List pngBytes, String qrName) async {
    if (_format == 'pdf') {
      await QRGeneratorService.saveAsPdf(pngBytes, qrName);
    } else {
      await QRGeneratorService.saveAsJpg(pngBytes, qrName);
    }
  }

  Future<void> _updateHistory(String qrName, String url) async {
    final qrItem = QRItem(name: qrName, url: url);
    final value = qrItem.toStorageString();

    if (isEditMode) {
      await StorageService.updateGenerateItem(editIndex!, value);
    } else {
      await StorageService.addGenerateItem(value);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}