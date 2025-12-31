import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_scanner/view/qr_code_link_preview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_scanner/view/qr_pdf_result_page.dart';


final ImagePicker picker = ImagePicker();

Future<void> pickImageFromGallery(
  BuildContext context,
  Function(String) addItem,
) async {
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image == null) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QrCodeGallery(imagePath: image.path, onOpen: addItem),
    ),
  );
}

Future<void> pickPdfFromGallery(BuildContext context, Function(String) addItem) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result == null || result.files.single.path == null) return;

  final pdfPath = result.files.single.path!;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => QrPdfResultPage(
        pdfPath: pdfPath,
        onOpen: addItem,
      ),
    ),
  );
}