import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex;

  NavigationProvider({int initialIndex = 0}) : _currentIndex = initialIndex;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
