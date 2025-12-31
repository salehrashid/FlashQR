import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerService {
  static Future<String?> scanFromImage(String imagePath) async {
    final controller = MobileScannerController();
    final result = await controller.analyzeImage(imagePath);

    if (result != null && result.barcodes.isNotEmpty) {
      return result.barcodes.first.rawValue;
    }

    return null;
  }

  static bool isUrl(String? value) {
    if (value == null) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static String formatUrl(String value) {
    String finalValue = value.trim();

    if (!finalValue.startsWith('http://') && !finalValue.startsWith('https://')) {
      finalValue = 'https://$finalValue';
    }

    return finalValue;
  }
}