import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure<T> with _$Failure<T> {
  const factory Failure.platformFailure({String? message}) = PlatformFailure;
  const factory Failure.formatExceptionFailure() = FormatExceptionFailure;
  const factory Failure.unableToProcess(dynamic error) = UnableToProcess;
  const factory Failure.unexpectedError(dynamic data) = UnexpectedError;
  const factory Failure.cacheReadFailure() = CacheReadFailure;
  const factory Failure.cacheWriteFailure() = CacheWriteFailure;
  const factory Failure.networkFailure({String? message}) = NetworkFailure;
}
