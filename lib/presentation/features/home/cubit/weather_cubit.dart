import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/core/usecases/usecase.dart';
import 'package:dayflow/core/usecases/weather/get_weather.dart';
import 'package:dayflow/infrastructure/extensions/failures.dart';
import 'package:dayflow/infrastructure/models/general/cubitStatus.dart';
import 'package:injectable/injectable.dart';
import 'weather_state.dart';

@injectable
class WeatherCubit extends Cubit<WeatherState> {
  final GetWeather _getWeather;

  WeatherCubit(this._getWeather) : super(const WeatherState());

  Future<void> loadWeather() async {
    emit(state.copyWith(
      status: const CubitStatus(statusType: CubitStatusType.loading),
    ));

    final result = await _getWeather(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: CubitStatus(
          statusType: CubitStatusType.failure,
          errorMsg: failure.getMessage(),
        ),
      )),
      (weather) => emit(state.copyWith(
        weather: weather,
        status: const CubitStatus(statusType: CubitStatusType.success),
      )),
    );
  }
}
