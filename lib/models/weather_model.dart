import 'hourly_weather_model.dart';
import 'air_quality_model.dart';

class WeatherData {
  final CurrentWeather current;
  final DailyForecast daily;
  final HourlyWeather hourly;
  final AirQuality? airQuality;

  WeatherData({
    required this.current,
    required this.daily,
    required this.hourly,
    this.airQuality,
  });

  WeatherData copyWith({
    CurrentWeather? current,
    DailyForecast? daily,
    HourlyWeather? hourly,
    AirQuality? airQuality,
  }) {
    return WeatherData(
      current: current ?? this.current,
      daily: daily ?? this.daily,
      hourly: hourly ?? this.hourly,
      airQuality: airQuality ?? this.airQuality,
    );
  }

  factory WeatherData.fromJson(Map<String, dynamic> json, [AirQuality? airQuality]) {
    return WeatherData(
      current: CurrentWeather.fromJson(json['current']),
      daily: DailyForecast.fromJson(json['daily']),
      hourly: HourlyWeather.fromJson(json['hourly']),
      airQuality: airQuality,
    );
  }
}

class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double apparentTemperature;
  final double surfacePressure;
  final int windDirection;
  final double uvIndex;

  CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    this.apparentTemperature = 0.0,
    this.surfacePressure = 1013.0,
    this.windDirection = 0,
    this.uvIndex = 0.0,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: json['weather_code'] ?? 0,
      windSpeed: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble() ??
          ((json['temperature_2m'] as num?)?.toDouble() ?? 0.0),
      surfacePressure: (json['surface_pressure'] as num?)?.toDouble() ?? 1013.0,
      windDirection: (json['wind_direction_10m'] as num?)?.toInt() ?? 0,
      uvIndex: (json['uv_index'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyForecast {
  final List<String> time;
  final List<int> weatherCode;
  final List<double> temperatureMax;
  final List<double> temperatureMin;
  final List<String> sunrise;
  final List<String> sunset;
  final List<double> uvIndexMax;
  final List<int> precipitationProbabilityMax;

  DailyForecast({
    required this.time,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    this.sunrise = const [],
    this.sunset = const [],
    this.uvIndexMax = const [],
    this.precipitationProbabilityMax = const [],
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      time: List<String>.from(json['time'] ?? []),
      weatherCode: List<int>.from(json['weather_code'] ?? []),
      temperatureMax: List<double>.from(
          (json['temperature_2m_max'] ?? []).map((e) => (e as num).toDouble())),
      temperatureMin: List<double>.from(
          (json['temperature_2m_min'] ?? []).map((e) => (e as num).toDouble())),
      sunrise: List<String>.from(json['sunrise'] ?? []),
      sunset: List<String>.from(json['sunset'] ?? []),
      uvIndexMax: List<double>.from(
          (json['uv_index_max'] ?? []).map((e) => (e as num).toDouble())),
      precipitationProbabilityMax: List<int>.from(
          (json['precipitation_probability_max'] ?? []).map((e) => (e as num).toInt())),
    );
  }
}
