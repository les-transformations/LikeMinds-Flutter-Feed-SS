import 'package:flutter/material.dart';

class NavigationService {
  GlobalKey<NavigatorState> navigatorKey;

  NavigationService({required this.navigatorKey});

  bool checkNullState() {
    if (navigatorKey.currentState == null) {
      return true;
    } else {
      return false;
    }
  }

  Future<dynamic> navigateTo(Route route, {Object? arguments}) {
    debugPrint(navigatorKey.currentState!.toString());
    return navigatorKey.currentState!.push(route);
  }

  void goBack({Map<String, dynamic>? result}) {
    return navigatorKey.currentState!.pop(result ?? {});
  }
}
