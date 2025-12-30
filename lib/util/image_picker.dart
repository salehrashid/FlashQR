import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_scanner/view/qr_code_gallery.dart';

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
