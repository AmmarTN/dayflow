import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/i18n/strings.g.dart';

extension FailureMessage on Failure {
  String getMessage() {
    Failure a = this;
    return a.map(
      formatExceptionFailure: (_) => t.errors.failures.formatException,
      unableToProcess: (_) => t.errors.failures.unableToProcess,
      platformFailure: (f) => f.message ?? t.errors.failures.platformError,
      unexpectedError: (f) => t.errors.failures.unexpectedError,
      cacheReadFailure: (_) => t.errors.failures.cacheReadFailure,
      cacheWriteFailure: (_) => t.errors.failures.cacheWriteFailure,
      networkFailure: (f) => f.message ?? t.errors.failures.unexpectedError,
    );
  }
}
