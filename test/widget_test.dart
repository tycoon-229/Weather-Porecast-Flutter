import 'package:flutter_test/flutter_test.dart';
import 'package:weather/utils/weather_utils.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/models/hourly_weather_model.dart';
import 'package:weather/models/city_model.dart';
import 'package:weather/models/air_quality_model.dart';

void main() {
  test('WeatherUtils returns valid UV info', () {
    final lowUv = WeatherUtils.getUvInfo(1.5);
    expect(lowUv.label, 'Thấp');

    final highUv = WeatherUtils.getUvInfo(7.2);
    expect(highUv.label, 'Cao');
  });

  test('WeatherData parses new Phase 1 fields correctly', () {
    final mockJson = {
      'current': {
        'temperature_2m': 30.5,
        'relative_humidity_2m': 65,
        'apparent_temperature': 34.2,
        'weather_code': 1,
        'surface_pressure': 1010.5,
        'wind_speed_10m': 12.0,
        'wind_direction_10m': 135,
        'uv_index': 6.5,
      },
      'daily': {
        'time': ['2026-10-22'],
        'weather_code': [1],
        'temperature_2m_max': [33.0],
        'temperature_2m_min': [24.0],
        'sunrise': ['2026-10-22T05:54'],
        'sunset': ['2026-10-22T17:27'],
        'uv_index_max': [7.0],
        'precipitation_probability_max': [45],
      },
      'hourly': {
        'time': ['2026-10-22T14:00'],
        'temperature_2m': [30.5],
        'weather_code': [1],
        'precipitation_probability': [30],
        'uv_index': [5.0],
      },
    };

    final weatherData = WeatherData.fromJson(mockJson);
    expect(weatherData.current.apparentTemperature, 34.2);
    expect(weatherData.current.uvIndex, 6.5);
    expect(weatherData.current.surfacePressure, 1010.5);
    expect(weatherData.current.windDirection, 135);
    expect(weatherData.daily.sunrise.first, '2026-10-22T05:54');
    expect(weatherData.daily.sunset.first, '2026-10-22T17:27');
    expect(weatherData.daily.precipitationProbabilityMax.first, 45);
    expect(weatherData.hourly.precipitationProbability.first, 30);
  });

  test('City model serializes and deserializes correctly', () {
    final city = City(
      name: 'Nha Trang',
      latitude: 12.2461,
      longitude: 109.1897,
      country: 'VN',
      isCurrentLocation: true,
    );

    final jsonMap = city.toJson();
    final parsed = City.fromJson(jsonMap);

    expect(parsed.name, 'Nha Trang');
    expect(parsed.latitude, 12.2461);
    expect(parsed.longitude, 109.1897);
    expect(parsed.isCurrentLocation, true);
    expect(parsed == city, true);
  });

  test('AirQuality parses JSON and returns appropriate status', () {
    final aqiJson = {
      'current': {
        'us_aqi': 125,
        'pm2_5': 35.5,
        'pm10': 42.0,
        'carbon_monoxide': 400.0,
        'nitrogen_dioxide': 12.0,
        'ozone': 180.0,
      }
    };

    final aqi = AirQuality.fromJson(aqiJson);
    expect(aqi.aqi, 125);
    expect(aqi.pm25, 35.5);
    expect(aqi.pm10, 42.0);

    final status = aqi.getAqiStatus();
    expect(status.label, 'Kém');
  });
}
