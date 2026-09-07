import 'package:flutter/material.dart';
import 'package:weather_animation/weather_animation.dart';
import '../models/city_model.dart';

enum WeatherType { sunny, cloudy, rainy, snowy, thunder }

class WeatherUtils {
  static String getWeatherDescription(int code) {
    if (code == 0) return 'Trời quang';
    if (code >= 1 && code <= 3) return 'Nhiều mây';
    if (code >= 45 && code <= 48) return 'Sương mù';
    if (code >= 51 && code <= 67) return 'Mưa phùn/Mưa';
    if (code >= 71 && code <= 77) return 'Tuyết rơi';
    if (code >= 80 && code <= 82) return 'Mưa rào';
    if (code >= 95 && code <= 99) return 'Dông sét';
    return 'Không xác định';
  }

  static WeatherType getWeatherType(int code) {
    if (code == 0) return WeatherType.sunny;
    if (code >= 1 && code <= 3) return WeatherType.cloudy;
    if (code >= 45 && code <= 48) return WeatherType.cloudy;
    if (code >= 51 && code <= 67) return WeatherType.rainy;
    if (code >= 71 && code <= 77) return WeatherType.snowy;
    if (code >= 80 && code <= 82) return WeatherType.rainy;
    if (code >= 95 && code <= 99) return WeatherType.thunder;
    return WeatherType.sunny;
  }

  static WeatherScene getSchema(WeatherType type, Color color) {
    switch (type) {
      case WeatherType.sunny:
        return WeatherScene.scorchingSun;
      case WeatherType.cloudy:
        return WeatherScene.sunset;
      case WeatherType.rainy:
        return WeatherScene.rainyOvercast;
      case WeatherType.snowy:
        return WeatherScene.snowfall;
      case WeatherType.thunder:
        return WeatherScene.stormy;
    }
  }

  static final List<City> vietnamCities = [
    City(name: 'Hà Nội', latitude: 21.0285, longitude: 105.8542, country: 'VN'),
    City(name: 'TP. Hồ Chí Minh', latitude: 10.8231, longitude: 106.6297, country: 'VN'),
    City(name: 'Đà Nẵng', latitude: 16.0544, longitude: 108.2022, country: 'VN'),
    City(name: 'Hải Phòng', latitude: 20.8449, longitude: 106.6881, country: 'VN'),
    City(name: 'Cần Thơ', latitude: 10.0452, longitude: 105.7469, country: 'VN'),
    City(name: 'Huế', latitude: 16.4637, longitude: 107.5909, country: 'VN'),
    City(name: 'Nha Trang', latitude: 12.2461, longitude: 109.1897, country: 'VN'),
    City(name: 'Đà Lạt', latitude: 11.9404, longitude: 108.4583, country: 'VN'),
  ];
}
