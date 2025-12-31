import 'package:qr_scanner/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<List<String>> loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(scanHistoryKey) ?? [];
  }

  static Future<List<String>> loadGenerateHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(generateHistoryKey) ?? [];
  }

  static Future<void> saveScanHistory(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(scanHistoryKey, items);
  }

  static Future<void> saveGenerateHistory(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(generateHistoryKey, items);
  }

  static Future<void> addScanItem(String value) async {
    final items = await loadScanHistory();
    items.insert(0, value);
    await saveScanHistory(items);
  }

  static Future<void> addGenerateItem(String value) async {
    final items = await loadGenerateHistory();
    items.insert(0, value);
    await saveGenerateHistory(items);
  }

  static Future<void> updateGenerateItem(int index, String value) async {
    final items = await loadGenerateHistory();
    if (index < items.length) {
      items[index] = value;
      await saveGenerateHistory(items);
    }
  }
}