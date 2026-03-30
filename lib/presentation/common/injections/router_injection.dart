import 'package:dayflow/presentation/common/routes/router.dart';
import 'package:injectable/injectable.dart';


@module
abstract class RoutesInjectableModule {
  @lazySingleton
  AppRouter get appRouter => AppRouter();
}
