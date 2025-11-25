import 'package:flutter/material.dart';

class QRCodeGenerator extends StatelessWidget {
  const QRCodeGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("QR Code Generator"),
      ),
      body: const Center(
        child: Text(
          "Ini Dummy Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
