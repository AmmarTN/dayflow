import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/presentation/features/bottom_nav_layout_manager.dart/models/tabItem.dart';
import 'package:dayflow/presentation/features/bottom_nav_layout_manager.dart/widgets/CustomRowBottomNavBar.dart/BottomTabItem.dart';

class CustomRowBottomNavBar extends StatelessWidget {
  final double height;
  final double topBorderRadius;
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final List<MainTabItem> tabItems;

  final Color backgroundColor;
  const CustomRowBottomNavBar({
    super.key,
    required this.height,
    this.topBorderRadius = 0,
    required this.currentIndex,
    required this.onItemTap,
    required this.tabItems,
    required this.backgroundColor,
  }) : assert(currentIndex >= 0 && currentIndex < tabItems.length);

  @override
  Widget build(BuildContext context) {
    return NavBarContent(
        height: height,
        backgroundColor: backgroundColor,
        topBorderRadius: topBorderRadius,
        tabItems: tabItems,
        onItemTap: onItemTap);
  }
}

class NavBarContent extends StatelessWidget {
  const NavBarContent({
    super.key,
    required this.height,
    required this.backgroundColor,
    required this.topBorderRadius,
    required this.tabItems,
    required this.onItemTap,
  });

  final double height;
  final Color backgroundColor;
  final double topBorderRadius;
  final List<MainTabItem> tabItems;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
          ),
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(topBorderRadius),
              topRight: Radius.circular(topBorderRadius),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h),
            child: Row(
                children: tabItems.asMap().entries.map((entry) {
              int index = entry.key;
              final tabItem = entry.value;
              return Expanded(
                child: InkWell(
                  onTap: () => onItemTap(index),
                  child: BNavBarItem(
                    selected: tabItem.selected,
                    selectedPic: tabItem.selectedPic,
                    unselectedPic: tabItem.unselectedPic,
                    label: tabItem.label,
                  ),
                ),
              );
            }).toList()),
          ),
        ),
      ],
    );
  }
}
