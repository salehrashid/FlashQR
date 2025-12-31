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

const scanHistoryKey = 'qr_scan_history';
const generateHistoryKey = 'qr_generate_history';

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> scanItems = [];
  List<String> generateItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      scanItems = prefs.getStringList(scanHistoryKey) ?? [];
      generateItems = prefs.getStringList(generateHistoryKey) ?? [];
    });
  }

  Future<void> _saveScanItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(scanHistoryKey, scanItems);
  }

  Future<void> _addScanItem(String value) async {
    setState(() => scanItems.insert(0, value));
    await _saveScanItems();
  }

  void _removeScanItem(int index) {
    setState(() => scanItems.removeAt(index));
    _saveScanItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FlashQR"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Scan History"),
            Tab(text: "Generate History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildScanTab(), _buildGenerateTab()],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  /// ================= TAB 1 — SCAN =================

  Widget _buildScanTab() {
    if (scanItems.isEmpty) {
      return const Center(child: Text("No scan history"));
    }

    return ListView.builder(
      itemCount: scanItems.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: ValueKey(scanItems[index]),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            final ok = await _confirmDelete();
            if (ok) _removeScanItem(index);
            return false;
          },
          child: ListTile(
            title: Text(scanItems[index]),
            onTap: () => _openDialog(scanItems[index]),
          ),
        );
      },
    );
  }

  /// ================= TAB 2 — GENERATE =================

  Widget _buildGenerateTab() {
    if (generateItems.isEmpty) {
      return const Center(child: Text("No generated QR"));
    }

    return ListView.builder(
      itemCount: generateItems.length,
      itemBuilder: (_, index) {
        final url = generateItems[index];

        return ListTile(
          leading: const Icon(Icons.qr_code),
          title: Text(url),
          onTap: () {
            /// ⬅️ CLICKABLE → kembali ke Generator
            NavRouter.instance.pushNamed("/qr-code-generator", arguments: url);
          },
        );
      },
    );
  }

  /// ================= SPEED DIAL =================

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.qr_code),
          label: 'QR Code Generator',
          onTap: () async {
            final result = await NavRouter.instance.pushNamed(
              "/qr-code-generator",
            );

            /// kalau generator return URL → refresh tab
            if (result is String) {
              await _loadItems();
              _tabController.animateTo(1);
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan QR',
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              "/qr-code-scanner",
            );

            if (result is String) {
              await _addScanItem(result);
              _tabController.animateTo(0);
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.photo),
          label: 'Gallery',
          onTap: () => pickImageFromGallery(context, _addScanItem),
        ),
      ],
    );
  }

  /// ================= UTIL =================

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Delete item?"),
                content: const Text("This action cannot be undone."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Delete"),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _openDialog(String value) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("QR Data"),
            content: Text(value),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchURL(value);
                },
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
