import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:qr_scanner/navigator/nav_router.dart';
import 'package:qr_scanner/util/file_picker.dart';
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

  bool selectionMode = false;

  final Set<int> selectedScanIndexes = {};
  final Set<int> selectedGenerateIndexes = {};

  bool get isScanTab => _tabController.index == 0;

  Set<int> get currentSelected =>
      isScanTab ? selectedScanIndexes : selectedGenerateIndexes;

  List<String> get currentItems => isScanTab ? scanItems : generateItems;

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

  Future<void> _removeGeneratedItem(int index) async {
    setState(() {
      generateItems.removeAt(index);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(generateHistoryKey, generateItems);
  }

  Future<void> _deleteSelected() async {
    final ok = await _confirmDelete();
    if (!ok) return;

    setState(() {
      final sortedIndexes = currentSelected.toList()..sort((a, b) => b - a);
      for (final index in sortedIndexes) {
        currentItems.removeAt(index);
      }
      currentSelected.clear();
      selectionMode = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      isScanTab ? scanHistoryKey : generateHistoryKey,
      currentItems,
    );
  }

  void _removeScanItem(int index) {
    setState(() => scanItems.removeAt(index));
    _saveScanItems();
  }

  void _enterSelectionMode(int index) {
    setState(() {
      selectionMode = true;
      currentSelected.add(index);
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (currentSelected.contains(index)) {
        currentSelected.remove(index);
      } else {
        currentSelected.add(index);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      selectionMode = false;
      selectedScanIndexes.clear();
      selectedGenerateIndexes.clear();
    });
  }

  void _selectAll() {
    setState(() {
      if (currentSelected.length == currentItems.length) {
        currentSelected.clear();
      } else {
        currentSelected
          ..clear()
          ..addAll(List.generate(currentItems.length, (i) => i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (selectionMode && !didPop) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              selectionMode
                  ? Text("${currentSelected.length} selected")
                  : const Text("FlashQR"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading:
              selectionMode
                  ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelectionMode,
                  )
                  : null,
          actions:
              selectionMode
                  ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: _selectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          currentSelected.isEmpty ? null : _deleteSelected,
                    ),
                  ]
                  : [],
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
        floatingActionButton: selectionMode ? null : _buildSpeedDial(),
      ),
    );
  }

  /// ================= TAB 1 — SCAN =================

  Widget _buildScanTab() {
    if (scanItems.isEmpty) {
      return const Center(child: Text("No scan history. Click + to scan"));
    }

    return ListView.builder(
      itemCount: scanItems.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: ValueKey(scanItems[index]),

          direction:
              selectionMode
                  ? DismissDirection.none
                  : DismissDirection.endToStart,

          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),

          confirmDismiss:
              selectionMode
                  ? null
                  : (_) async {
                    final ok = await _confirmDelete();
                    if (ok) _removeScanItem(index);
                    return false;
                  },

          child: ListTile(
            leading:
                selectionMode
                    ? Checkbox(
                      value: selectedScanIndexes.contains(index),
                      onChanged: (_) => _toggleSelection(index),
                    )
                    : null,

            title: Text(scanItems[index]),

            onTap: () {
              if (selectionMode) {
                _toggleSelection(index);
              } else {
                _openDialog(scanItems[index]);
              }
            },

            onLongPress: () => _enterSelectionMode(index),
          ),
        );
      },
    );
  }

  /// ================= TAB 2 — GENERATE =================

  Widget _buildGenerateTab() {
    if (generateItems.isEmpty) {
      return const Center(child: Text("No generated QR. Click + to generate"));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: generateItems.length,
            itemBuilder: (_, index) {
              final item = generateItems[index];

              return Dismissible(
                key: ValueKey(item),
                direction:
                    selectionMode
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss:
                    selectionMode
                        ? null
                        : (_) async {
                          final ok = await _confirmDelete();
                          if (ok) _removeGeneratedItem(index);
                          return false;
                        },
                child: ListTile(
                  leading:
                      selectionMode
                          ? Checkbox(
                            value: selectedGenerateIndexes.contains(index),
                            onChanged: (_) => _toggleSelection(index),
                          )
                          : const Icon(Icons.qr_code),
                  title: Text(item),
                  onTap: () async {
                    if (selectionMode) {
                      _toggleSelection(index);
                      return;
                    }

                    final parts = item.split(' • ');
                    await NavRouter.instance.pushNamed(
                      "/qr-code-generator",
                      arguments: {
                        "index": index,
                        "name": parts.first,
                        "url": parts.length > 1 ? parts.last : '',
                      },
                    );
                    await _loadItems();
                  },
                  onLongPress: () => _enterSelectionMode(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ================= SPEED DIAL =================
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
                  pickImageFromGallery(context, _addScanItem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Scan from PDF'),
                onTap: () {
                  Navigator.pop(context);
                  pickPdfFromGallery(context, _addScanItem);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.qr_code),
          label: 'QR Code Generator',
          onTap: () async {
            await NavRouter.instance.pushNamed("/qr-code-generator");

            if (!mounted) return;

            await _loadItems();

            _tabController.animateTo(1);
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
          onTap: () => _showGalleryOptions(context),
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
