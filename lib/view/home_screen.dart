import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:qr_scanner/navigator/nav_router.dart';
import 'package:qr_scanner/util/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// Load from SharedPreferences
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      items = prefs.getStringList('qr_history') ?? [];
    });
  }

  /// Save to SharedPreferences
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('qr_history', items);
  }

  /// Add item (example usage)
  Future<void> _addItem(String value) async {
    setState(() => items.insert(0, value));
    await _saveItems();
  }

  /// Remove item
  Future<void> _removeItem(int index) async {
    setState(() => items.removeAt(index));
    await _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FlashQR"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          items.isEmpty
              ? const Center(
                child: Text(
                  "No data",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: ValueKey(items[index]),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("Delete this item?"),
                              content: const Text(
                                "This action cannot be undone.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                      );
                    },
                    onDismissed: (_) => _removeItem(index),
                    child: ListTile(
                      title: Text(items[index]),
                      onTap: () => _openDialog(items[index]),
                    ),
                  );
                },
              ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'QR Code Generator',
            onTap: () => NavRouter.instance.pushNamed("/qr-code-generator"),
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                "/qr-code-scanner",
              );

              if (result != null && result is String) {
                await _addItem(result);
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.photo),
            label: 'Gallery',
            onTap: pickImageFromGallery,
          ),
        ],
      ),
    );
  }

  void _openDialog(String value) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("QR Data"),
            content: Text(value),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => launchURL(value),
                child: const Text("Open"),
              ),
            ],
          ),
    );
  }

  void launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $urlString");
    }
  }
}
