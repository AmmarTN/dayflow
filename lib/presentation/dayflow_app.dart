import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/i18n/strings.g.dart';
import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/core/usecases/tasks/get_tasks.dart';
import 'package:dayflow/core/usecases/tasks/save_tasks.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/common/cubit/bottom_nav_bar/bottom_nav_bar_cubit.dart';
import 'package:dayflow/presentation/common/cubit/language/language_cubit.dart';
import 'package:dayflow/presentation/common/routes/router.dart';
import 'package:dayflow/presentation/common/theme/app_theme_data.dart';
import 'package:dayflow/presentation/common/widgets/scroll_behaviors/scroll_glow_indicator_disabler.dart';
import 'package:dayflow/presentation/features/home/cubit/tasks_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/weather_cubit.dart';
import 'package:dayflow/services/widget_data_sync.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DayFlowAppProvided extends StatelessWidget {
  const DayFlowAppProvided({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LanguageCubit>(
            lazy: false,
            create: (context) => getIt<LanguageCubit>()..setLanguage(),
          ),
          BlocProvider(create: (context) => getIt<BottomNavbarCubit>()),
          BlocProvider(create: (context) => getIt<TasksCubit>()..loadTasks()),
          BlocProvider(
            create: (context) => getIt<WeatherCubit>()..loadWeather(),
          ),
        ],
        child: const DayFlowApp(),
      ),
    );
  }
}

class DayFlowApp extends StatefulWidget {
  const DayFlowApp({super.key});

  @override
  State<DayFlowApp> createState() => _DayFlowAppState();
}

class _DayFlowAppState extends State<DayFlowApp> {
  StreamSubscription<AlarmSet>? _alarmSub;
  final Set<int> _handledAlarmIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    if (defaultTargetPlatform != TargetPlatform.android) {
      _alarmSub = Alarm.ringing.listen(_onRingingChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _alarmSub?.cancel();
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver = _AppLifecycleObserver(
    onResumed: () async {
      WidgetDataSync.sync();
      if (defaultTargetPlatform != TargetPlatform.android || !mounted) return;
      final changed = await getIt<NotificationService>()
          .syncPendingAndroidAlarmActions(
            getIt<GetTasks>(),
            getIt<SaveTasks>(),
          );
      if (!changed || !mounted) return;
      context.read<TasksCubit>().loadTasks();
    },
  );

  void _onRingingChanged(AlarmSet alarmSet) {
    if (alarmSet.alarms.isEmpty) {
      _handledAlarmIds.clear();
      return;
    }
    for (final alarm in alarmSet.alarms) {
      if (_handledAlarmIds.contains(alarm.id)) continue;
      _handledAlarmIds.add(alarm.id);

      final taskId = alarm.payload;
      if (taskId != null && taskId.isNotEmpty) {
        getIt<AppRouter>().push(AlarmRoute(taskId: taskId));
      }
    }
  }

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
            theme: AppThemeData.getAppThemeData(
              language: localLang,
              context: context,
            ),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
          ),
        );
      },
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver({required this.onResumed});

  final Future<void> Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResumed());
    }
  }
}
