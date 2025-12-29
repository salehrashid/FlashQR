import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:qr_scanner/navigator/nav_router.dart';
import 'package:qr_scanner/util/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("FlashQR"),
      ),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: ListTile(
              title: Text("data $index", style: TextStyle(fontSize: 20)),
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (BuildContext context) => AlertDialog(
                          title: Text("data $index"),
                          content: Text("data $index"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: launchURL,
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                  ),
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
            onTap: () => NavRouter.instance.pushNamed("/qr-code-scanner"),
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

  launchURL() async {
    final Uri url = Uri.parse('https://flutter.dev');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
