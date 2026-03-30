import 'package:flutter/material.dart';

class MainTabItem {
  final String unselectedPic;
  final String selectedPic;
  bool selected;
  final String label;

  MainTabItem({
    required this.unselectedPic,
    required this.selectedPic,
    required this.selected,
    required this.label,
  });
}
