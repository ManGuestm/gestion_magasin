import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?> push<T>(Route<T> route) {
    return navigatorKey.currentState!.push<T>(route);
  }

  void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }

  Future<T?> pushReplacement<T, TO>(Route<T> newRoute, {TO? result}) {
    return navigatorKey.currentState!.pushReplacement<T, TO>(newRoute, result: result);
  }

  Future<T?> pushAndRemoveUntil<T>(Route<T> newRoute, bool Function(Route<dynamic>) predicate) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(newRoute, predicate);
  }

  void popUntil(bool Function(Route<dynamic>) predicate) {
    return navigatorKey.currentState!.popUntil(predicate);
  }

  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  Future<bool> maybePop<T>([T? result]) {
    return navigatorKey.currentState!.maybePop<T>(result);
  }
}