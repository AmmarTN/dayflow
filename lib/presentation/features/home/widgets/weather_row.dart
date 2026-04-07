import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dayflow/infrastructure/models/general/cubitStatus.dart';
import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:dayflow/presentation/common/theme/app_text_styles.dart';
import 'package:dayflow/presentation/features/home/cubit/weather_cubit.dart';
import 'package:dayflow/presentation/features/home/cubit/weather_state.dart';

class WeatherRow extends StatelessWidget {
  final bool compact;

  const WeatherRow({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        if (state.status.statusType == CubitStatusType.loading) {
          return _buildLoading(context);
        }

        if (state.weather == null) {
          return _buildError(context);
        }

        return _buildContent(context, state);
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: compact ? 12.sp : 14.sp,
          height: compact ? 12.sp : 14.sp,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.darkTextMuted,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            'Loading weather...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? AppTextStyles(context).px12wRegular()
                        : AppTextStyles(context).px13wRegular())
                    .copyWith(color: AppColors.darkTextMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<WeatherCubit>().loadWeather(),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: AppColors.darkTextMuted,
            size: compact ? 16.sp : 18.sp,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              'Weather unavailable',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? AppTextStyles(context).px12wRegular()
                          : AppTextStyles(context).px13wRegular())
                      .copyWith(color: AppColors.darkTextMuted),
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.refresh_rounded,
            color: AppColors.darkTextMuted,
            size: compact ? 12.sp : 14.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherState state) {
    final weather = state.weather!;
    final temp = weather.temperature.round();

    return Row(
      children: [
        Text(
          _weatherEmoji(weather.weatherCode),
          style: TextStyle(fontSize: compact ? 18.sp : 20.sp),
        ),
        SizedBox(width: 6.w),
        Text(
          '$temp\u00B0',
          style:
              (compact
                      ? AppTextStyles(context).px13wMedium()
                      : AppTextStyles(context).px14wMedium())
                  .copyWith(color: AppColors.darkTextPrimary),
        ),
        if (weather.cityName.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Icon(
            Icons.navigation_outlined,
            color: AppColors.darkTextMuted,
            size: compact ? 11.sp : 12.sp,
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              weather.cityName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? AppTextStyles(context).px12wRegular()
                          : AppTextStyles(context).px13wRegular())
                      .copyWith(color: AppColors.darkTextSecondary),
            ),
          ),
        ],
      ],
    );
  }

  /// Maps WMO weather codes to native platform emojis.
  /// https://open-meteo.com/en/docs#weathervariables
  String _weatherEmoji(int code) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 20;

    switch (code) {
      case 0:
        return isNight ? '🌙' : '☀️';
      case 1:
        return isNight ? '🌙' : '🌤️';
      case 2:
        return '⛅';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
        return '🌦️';
      case 56:
      case 57:
        return '🌧️';
      case 61:
      case 63:
        return '🌧️';
      case 65:
        return '🌧️';
      case 66:
      case 67:
        return '🧊';
      case 71:
      case 73:
        return '🌨️';
      case 75:
      case 77:
        return '❄️';
      case 80:
      case 81:
      case 82:
        return '🌧️';
      case 85:
      case 86:
        return '🌨️';
      case 95:
        return '⛈️';
      case 96:
      case 99:
        return '⛈️';
      default:
        return '☁️';
    }
  }
}
