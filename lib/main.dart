import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/core/debug/app_bloc_observer.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/dayflow_app.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = AppBlocObserver();

      unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));

      await configureDependencies();

      runApp(const DayFlowAppProvided());
    },
    (e, stackTrace) {
      debugPrint("[Error] Top level main error: $e");
      throw e;
    },
  );
}
