import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/common/cubit/bottom_nav_bar/bottom_nav_bar_cubit.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';
import 'package:dayflow/presentation/common/routes/router.dart';
import 'package:dayflow/presentation/common/theme/app_theme_data.dart';
import 'package:dayflow/presentation/common/widgets/scroll_behaviors/scroll_glow_indicator_disabler.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/weather_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DayFlowAppProvided extends StatelessWidget {
  const DayFlowAppProvided({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LanguageCubit>(lazy: false, create: (context) => getIt<LanguageCubit>()..setLanguage()),
          BlocProvider(create: (context) => getIt<BottomNavbarCubit>()),
          BlocProvider(create: (context) => getIt<TasksCubit>()..loadTasks()),
          BlocProvider(create: (context) => getIt<WeatherCubit>()..loadWeather()),
        ],
        child: const DayFlowApp(),
      ),
    );
  }
}

class DayFlowApp extends StatelessWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LocaleLanguage>(
      builder: (context, localLang) {
        return ScreenUtilInit(
          designSize: const Size(375, 831),
          useInheritedMediaQuery: true,
          minTextAdapt: true,
          builder: (context, _) => MaterialApp.router(
            routerConfig: getIt<AppRouter>().config(),
            debugShowCheckedModeBanner: false,
            title: 'DayFlow',
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: NoGlowBehavior(),
                child: child!,
              );
            },
            theme: AppThemeData.getAppThemeData(language: localLang, context: context),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
          ),
        );
      },
    );
  }
}
