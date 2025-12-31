import 'package:flutter/material.dart';
import 'package:qr_scanner/navigator/nav_router.dart';
import 'package:qr_scanner/services/storage_service.dart';
import 'package:qr_scanner/widgets/speed_dial_menu.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/qr_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========== DATA MANAGEMENT ==========

  Future<void> _loadItems() async {
    final scan = await StorageService.loadScanHistory();
    final generate = await StorageService.loadGenerateHistory();
    
    setState(() {
      scanItems = scan;
      generateItems = generate;
    });
  }

  Future<void> _addScanItem(String value) async {
    await StorageService.addScanItem(value);
    await _loadItems();
  }

  Future<void> _removeItem(int index) async {
    setState(() {
      currentItems.removeAt(index);
    });

    if (isScanTab) {
      await StorageService.saveScanHistory(scanItems);
    } else {
      await StorageService.saveGenerateHistory(generateItems);
    }
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

    if (isScanTab) {
      await StorageService.saveScanHistory(scanItems);
    } else {
      await StorageService.saveGenerateHistory(generateItems);
    }
  }

  // ========== SELECTION MODE ==========

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

  // ========== UI BUILD ==========

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
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [_buildScanTab(), _buildGenerateTab()],
        ),
        floatingActionButton: selectionMode ? null : _buildFloatingButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
                  onPressed: currentSelected.isEmpty ? null : _deleteSelected,
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
    );
  }

  Widget _buildFloatingButton() {
    return SpeedDialMenu(
      onScanResult: (value) async {
        await _addScanItem(value);
        _tabController.animateTo(0);
      },
      onGeneratePressed: () async {
        await NavRouter.instance.pushNamed("/qr-code-generator");
        if (!mounted) return;
        await _loadItems();
        _tabController.animateTo(1);
      },
      onScanPressed: () async {
        final result = await Navigator.pushNamed(context, "/qr-code-scanner");
        if (result is String) {
          await _addScanItem(result);
          _tabController.animateTo(0);
        }
      },
    );
  }

  // ========== SCAN TAB ==========

  Widget _buildScanTab() {
    if (scanItems.isEmpty) {
      return const Center(child: Text("No scan history. Click + to scan"));
    }

    return ListView.builder(
      itemCount: scanItems.length,
      itemBuilder: (context, index) => _buildScanItem(index),
    );
  }

  Widget _buildScanItem(int index) {
    return Dismissible(
      key: ValueKey(scanItems[index]),
      direction:
          selectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss:
          selectionMode
              ? null
              : (_) async {
                final ok = await _confirmDelete();
                if (ok) await _removeItem(index);
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
  }

  // ========== GENERATE TAB ==========

  Widget _buildGenerateTab() {
    if (generateItems.isEmpty) {
      return const Center(child: Text("No generated QR. Click + to generate"));
    }

    return ListView.builder(
      itemCount: generateItems.length,
      itemBuilder: (context, index) => _buildGenerateItem(index),
    );
  }

  Widget _buildGenerateItem(int index) {
    final item = generateItems[index];

    return Dismissible(
      key: ValueKey(item),
      direction:
          selectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss:
          selectionMode
              ? null
              : (_) async {
                final ok = await _confirmDelete();
                if (ok) await _removeItem(index);
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
        onTap: () => _onGenerateItemTap(index, item),
        onLongPress: () => _enterSelectionMode(index),
      ),
    );
  }

  Future<void> _onGenerateItemTap(int index, String item) async {
    if (selectionMode) {
      _toggleSelection(index);
      return;
    }

    final qrItem = QRItem.fromStorageString(item);
    await NavRouter.instance.pushNamed(
      "/qr-code-generator",
      arguments: {
        "index": index,
        "name": qrItem.name,
        "url": qrItem.url,
      },
    );
    await _loadItems();
  }

  // ========== UTILITY WIDGETS ==========

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

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
                  _launchURL(value);
                },
                child: const Text("Open"),
              ),
            ],
          ),
    );
  }

  void _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $urlString");
    }
  }
}