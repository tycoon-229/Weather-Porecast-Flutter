import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherApiService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
          '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
          '&hourly=temperature_2m,weather_code'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min'
          '&timezone=auto',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
