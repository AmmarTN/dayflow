import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alarm/alarm.dart';
import 'package:dayflow/core/debug/app_bloc_observer.dart';
import 'package:dayflow/core/services/notification_service.dart';
import 'package:dayflow/core/usecases/tasks/get_tasks.dart';
import 'package:dayflow/core/usecases/tasks/save_tasks.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/dayflow_app.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Task ID of an alarm that was already ringing when the app cold-started.
/// Read once by the splash page and then cleared.
String? pendingAlarmTaskId;

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = AppBlocObserver();

      unawaited(
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      );

      tz_data.initializeTimeZones();
      await Alarm.init();

      // If the app was cold-started because an alarm is ringing, capture the
      // task ID so the splash page can route directly to the alarm screen.
      if (defaultTargetPlatform != TargetPlatform.android) {
        final ringingAlarms = Alarm.ringing.value.alarms;
        if (ringingAlarms.isNotEmpty) {
          final first = ringingAlarms.first;
          pendingAlarmTaskId = first.payload;
        }
      }

      await configureDependencies();
      await getIt<NotificationService>().init();
      await getIt<NotificationService>().syncPendingAndroidAlarmActions(
        getIt<GetTasks>(),
        getIt<SaveTasks>(),
      );

      runApp(const DayFlowAppProvided());
    },
    (e, stackTrace) {
      debugPrint("[Error] Top level main error: $e");
      throw e;
    },
  );
}
