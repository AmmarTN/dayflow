import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(level: kDebugMode ? Level.debug : Level.off);

void inspector(Object object) {
  if (kDebugMode) {
    inspect(object);
  }
}
