import 'package:flutter/material.dart';

import 'navigator/nav_router.dart';
import 'view/home_screen.dart';
import 'view/qr_code_generator.dart';
import 'view/qr_code_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavRouter.instance.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: "/",
      routes: {
        "/": (BuildContext context) {
          return const HomePage();
        },
        "/qr-code-generator": (BuildContext context) {
          return const QRCodeGenerator();
        },
        "/qr-code-scanner": (BuildContext context) {
          return const QRCodeScanner();
        },
      },
    );
  }
}

