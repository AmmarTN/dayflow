import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/infrastructure/models/weather/weather_model.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class IWeatherRemoteDataSource {
  Future<Either<Failure, WeatherModel>> fetchWeather(
    double lat,
    double lon,
    String cityName,
  );
}

@Singleton(as: IWeatherRemoteDataSource)
class WeatherRemoteDataSourceImpl implements IWeatherRemoteDataSource {
  @override
  Future<Either<Failure, WeatherModel>> fetchWeather(
    double lat,
    double lon,
    String cityName,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code'
        '&timezone=auto',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return Left(Failure.networkFailure(
          message: 'Weather API returned ${response.statusCode}',
        ));
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>;

      final weather = WeatherModel(
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        cityName: cityName,
      );

      return Right(weather);
    } catch (e) {
      return Left(Failure.networkFailure(message: e.toString()));
    }
  }
}
