import 'dart:io';

class AppEnvState {
  AppEnvState._();

  static bool get isProd => false;
  static bool get isStaging => false;
  static bool get isDevelopment => true;
  static bool get isAndroid => Platform.isAndroid;

  static String get appVersion => 'Ver 1.0';
}
