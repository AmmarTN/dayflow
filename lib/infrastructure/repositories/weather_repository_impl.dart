import 'package:dartz/dartz.dart';
import 'package:dayflow/core/erros/failures.dart';
import 'package:dayflow/infrastructure/datasources/remote_datasources/weather_remote_data_source.dart';
import 'package:dayflow/infrastructure/models/weather/weather_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:injectable/injectable.dart';

abstract class IWeatherRepository {
  Future<Either<Failure, WeatherModel>> getWeather();
}

@Singleton(as: IWeatherRepository)
class WeatherRepositoryImpl implements IWeatherRepository {
  final IWeatherRemoteDataSource _remoteDataSource;

  WeatherRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, WeatherModel>> getWeather() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(
          Failure.networkFailure(message: 'Location services are disabled'),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(
            Failure.networkFailure(message: 'Location permission denied'),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(
          Failure.networkFailure(message: 'Location permission permanently denied'),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String cityName = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          cityName = placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              placemarks.first.administrativeArea ??
              '';
        }
      } catch (_) {
        // Geocoding can fail silently — we still have coordinates for weather
      }

      return _remoteDataSource.fetchWeather(
        position.latitude,
        position.longitude,
        cityName,
      );
    } catch (e) {
      return Left(Failure.networkFailure(message: e.toString()));
    }
  }
}
