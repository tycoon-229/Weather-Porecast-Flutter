import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/air_quality_model.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _airQualityUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final weatherUrl = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,uv_index'
      '&hourly=temperature_2m,weather_code,precipitation_probability,uv_index'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max'
      '&timezone=auto',
    );

    final aqiUrl = Uri.parse(
      '$_airQualityUrl?latitude=$lat&longitude=$lon'
      '&current=us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,ozone'
      '&timezone=auto',
    );

    final weatherFuture = http.get(weatherUrl);
    final aqiFuture = http.get(aqiUrl).catchError((_) => http.Response('{}', 500));

    final results = await Future.wait([weatherFuture, aqiFuture]);
    final weatherRes = results[0];
    final aqiRes = results[1];

    if (weatherRes.statusCode == 200) {
      AirQuality? airQuality;
      if (aqiRes.statusCode == 200) {
        try {
          airQuality = AirQuality.fromJson(json.decode(aqiRes.body));
        } catch (_) {}
      }
      return WeatherData.fromJson(json.decode(weatherRes.body), airQuality);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
