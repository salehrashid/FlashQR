import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:qr_scanner/utils/file_picker.dart';

class SpeedDialMenu extends StatelessWidget {
  final Function(String) onScanResult;
  final VoidCallback onGeneratePressed;
  final VoidCallback onScanPressed;

  const SpeedDialMenu({
    super.key,
    required this.onScanResult,
    required this.onGeneratePressed,
    required this.onScanPressed,
  });

  void _showGalleryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Scan from Image'),
                onTap: () {
                  Navigator.pop(context);
                  pickImageFromGallery(context, onScanResult);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Scan from PDF'),
                onTap: () {
                  Navigator.pop(context);
                  pickPdfFromGallery(context, onScanResult);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.qr_code),
          label: 'QR Code Generator',
          onTap: onGeneratePressed,
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan QR',
          onTap: onScanPressed,
        ),
        SpeedDialChild(
          child: const Icon(Icons.photo),
          label: 'Gallery',
          onTap: () => _showGalleryOptions(context),
        ),
      ],
    );
  }
}