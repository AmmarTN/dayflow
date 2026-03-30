import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/core/usecases/usecase.dart';
import 'package:dayflow/infrastructure/models/weather/weather_model.dart';
import 'package:dayflow/infrastructure/repositories/weather_repository_impl.dart';
import 'package:injectable/injectable.dart';

@singleton
class GetWeather extends Usecase<WeatherModel, NoParams> {
  final IWeatherRepository _repository;

  GetWeather(this._repository);

  @override
  Future<Either<Failure, WeatherModel>> call(NoParams params) {
    return _repository.getWeather();
  }
}
