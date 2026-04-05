import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';
import 'package:dayflow/presentation/features/bottom_nav_layout_manager.dart/bottom_nav_layout_widget.dart';
import 'package:dayflow/presentation/features/alarm/pages/alarm_page.dart';
import 'package:dayflow/presentation/features/home/pages/home_page.dart';
import 'package:dayflow/presentation/features/splash_page/splash_page.dart';

part 'router.gr.dart';

const int _duration = 300;

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();
  @override
  final List<AutoRoute> routes = [
    CustomRoute(
      path: '/',
      page: SplashRoute.page,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      durationInMilliseconds: _duration,
    ),
    CustomRoute(
      page: HomeRoute.page,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      durationInMilliseconds: _duration,
    ),
    CustomRoute(
      page: AlarmRoute.page,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      durationInMilliseconds: _duration,
    ),
  ];

  static Widget localisedLateralTransition(context, animation, secondaryAnimation, child) {
    final isRTL = Localizations.localeOf(context).languageCode == LocaleLanguage.ar.name;
    final transitionBuilder = isRTL ? TransitionsBuilders.slideRight : TransitionsBuilders.slideLeft;

    return transitionBuilder(context, animation, secondaryAnimation, child);
  }
}
