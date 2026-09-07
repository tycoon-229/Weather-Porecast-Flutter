import 'hourly_weather_model.dart';

class WeatherData {
  final CurrentWeather current;
  final DailyForecast daily;
  final HourlyWeather hourly;

  WeatherData({required this.current, required this.daily, required this.hourly});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: CurrentWeather.fromJson(json['current']),
      daily: DailyForecast.fromJson(json['daily']),
      hourly: HourlyWeather.fromJson(json['hourly']),
    );
  }
}

class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;

  CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: json['temperature_2m']?.toDouble() ?? 0.0,
      weatherCode: json['weather_code'] ?? 0,
      windSpeed: json['wind_speed_10m']?.toDouble() ?? 0.0,
      humidity: json['relative_humidity_2m']?.toInt() ?? 0,
    );
  }
}

class DailyForecast {
  final List<String> time;
  final List<int> weatherCode;
  final List<double> temperatureMax;
  final List<double> temperatureMin;

  DailyForecast({
    required this.time,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      time: List<String>.from(json['time']),
      weatherCode: List<int>.from(json['weather_code']),
      temperatureMax: List<double>.from(json['temperature_2m_max'].map((e) => e.toDouble())),
      temperatureMin: List<double>.from(json['temperature_2m_min'].map((e) => e.toDouble())),
    );
  }
}
