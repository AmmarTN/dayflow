import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dayflow/infrastructure/models/general/cubitStatus.dart';
import 'package:dayflow/infrastructure/models/weather/weather_model.dart';

part 'weather_state.freezed.dart';

@freezed
class WeatherState with _$WeatherState {
  const factory WeatherState({
    @Default(CubitStatus()) CubitStatus status,
    WeatherModel? weather,
  }) = _WeatherState;
}
