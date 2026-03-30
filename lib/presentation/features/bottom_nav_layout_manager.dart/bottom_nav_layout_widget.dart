import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/common/constants/assets_constants.dart';
import 'package:dayflow/presentation/common/cubit/bottom_nav_bar/bottom_nav_bar_cubit.dart';
import 'package:dayflow/presentation/features/bottom_nav_layout_manager.dart/models/tabItem.dart';
import 'widgets/BottomNavLayoutResources/layout.dart';
import 'widgets/BottomNavLayoutResources/page_stack.dart';
import 'widgets/CustomRowBottomNavBar.dart/CustomRowBottomNavBar.dart';

@RoutePage()
class BottomNavLayoutPage extends StatefulWidget {
  const BottomNavLayoutPage({super.key});

  @override
  State<BottomNavLayoutPage> createState() => _BottomNavLayoutPageState();
}

class _BottomNavLayoutPageState extends State<BottomNavLayoutPage> {
  final myPageStack = getIt<ReorderToFrontPageStack>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Platform.isIOS ? Colors.white : Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        minimum: const EdgeInsets.only(bottom: 0),
        child: WillPopScope(
          onWillPop: () {
            if (myPageStack.stack.length == 1) return Future.value(false);
            if (myPageStack.peek() == 0) {
              myPageStack.stack.clear();
              return Future.value(false);
            }
            return Future.value(true);
          },
          child: BottomNavLayoutContent(myPageStack: myPageStack),
        ),
      ),
    );
  }
}

class BottomNavLayoutContent extends StatelessWidget {
  const BottomNavLayoutContent({super.key, required this.myPageStack});
  final ReorderToFrontPageStack myPageStack;

  @override
  Widget build(BuildContext context) {
    final bottomNavbarCubit = context.watch<BottomNavbarCubit>();

    return BottomNavLayout(
      pages: [
        (navKey) => const Scaffold(body: Center(child: Text('Home'))),
        (navKey) => const Scaffold(body: Center(child: Text('Settings'))),
      ],

      bottomNavigationBar: (currentIndex, onTap) {
        return CustomRowBottomNavBar(
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor!,
          currentIndex: currentIndex,
          topBorderRadius: 24.r,
          height: 100.h,
          tabItems: [
            MainTabItem(
              selected: currentIndex == 0,
              selectedPic: MainSvgImageConstants.navbarHomeSelected,
              unselectedPic: MainSvgImageConstants.navbarHomeUnselected,
              label: t.nav_bar_items.home,
            ),
            MainTabItem(
              selected: currentIndex == 1,
              selectedPic: MainSvgImageConstants.navbarProfileSelected,
              unselectedPic: MainSvgImageConstants.navbarProfileUnselected,
              label: t.nav_bar_items.profile,
            ),
          ],
          onItemTap: (index) {
            onTap(index);
          },
        );
      },
      savePageState: true,
      lazyLoadPages: true,
      pageStack: myPageStack,
      extendBody: true,
      resizeToAvoidBottomInset: false,
    );
  }
}
