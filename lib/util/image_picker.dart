import 'package:image_picker/image_picker.dart';

final ImagePicker picker = ImagePicker();

Future<void> pickImageFromGallery() async {
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    print("Image path: ${image.path}");
  }
}
