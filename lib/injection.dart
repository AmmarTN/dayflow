import 'package:get_it/get_it.dart';
import 'package:injectable/src/injectable_annotations.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async => await getIt.init();
