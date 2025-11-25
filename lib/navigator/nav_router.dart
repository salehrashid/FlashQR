import 'package:flutter/material.dart';

class NavRouter {
  NavRouter._privateConstructor();
  static final NavRouter instance = NavRouter._privateConstructor();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic>? pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  void pop() {
    navigatorKey.currentState?.pop();
  }
}
