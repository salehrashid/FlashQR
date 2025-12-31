import 'dart:io';
import 'dart:typed_data';
import 'package:media_scanner/media_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:qr_scanner/utils/constant.dart';

class QRGeneratorService {
  static String sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  static Uint8List convertPngToJpgWithWhiteBg(Uint8List pngBytes) {
    final pngImage = img.decodeImage(pngBytes)!;

    final whiteBg = img.Image(width: pngImage.width, height: pngImage.height);

    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(whiteBg, pngImage);

    return Uint8List.fromList(img.encodeJpg(whiteBg, quality: 100));
  }

  static Future<Directory> getFlashQRDir() async {
    final dir = Directory(flashQRDirectory);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> saveAsJpg(
    Uint8List pngBytes,
    String fileName,
  ) async {
    final dir = await getFlashQRDir();
    final safeName = sanitizeFileName(fileName);
    final savedPath = "${dir.path}/$safeName.jpg";

    final jpgBytes = convertPngToJpgWithWhiteBg(pngBytes);
    await File(savedPath).writeAsBytes(jpgBytes);

    await MediaScanner.loadMedia(path: savedPath);

    return savedPath;
  }

  static Future<String> saveAsPdf(
    Uint8List pngBytes,
    String fileName,
  ) async {
    final dir = await getFlashQRDir();
    final safeName = sanitizeFileName(fileName);
    final savedPath = "${dir.path}/$safeName.pdf";

    final pdf = pw.Document();
    final imgPdf = pw.MemoryImage(pngBytes);

    pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(imgPdf))));

    await File(savedPath).writeAsBytes(await pdf.save());

    await MediaScanner.loadMedia(path: savedPath);

    return savedPath;
  }
}