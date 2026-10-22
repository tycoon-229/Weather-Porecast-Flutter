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

  static IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code >= 45 && code <= 48) return Icons.cloud;
    if (code >= 51 && code <= 67) return Icons.water_drop;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.shower;
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.wb_sunny;
  }

  static String getWindDirection(int degrees) {
    final deg = (degrees % 360 + 360) % 360;
    if (deg >= 337.5 || deg < 22.5) return 'Bắc (N)';
    if (deg >= 22.5 && deg < 67.5) return 'Đông Bắc (NE)';
    if (deg >= 67.5 && deg < 112.5) return 'Đông (E)';
    if (deg >= 112.5 && deg < 157.5) return 'Đông Nam (SE)';
    if (deg >= 157.5 && deg < 202.5) return 'Nam (S)';
    if (deg >= 202.5 && deg < 247.5) return 'Tây Nam (SW)';
    if (deg >= 247.5 && deg < 292.5) return 'Tây (W)';
    return 'Tây Bắc (NW)';
  }

  static ({String label, Color color, String advice}) getUvInfo(double uv) {
    if (uv <= 2.5) {
      return (label: 'Thấp', color: Colors.greenAccent, advice: 'An toàn khi hoạt động ngoài trời');
    } else if (uv <= 5.5) {
      return (label: 'Trung bình', color: Colors.amberAccent, advice: 'Nên đeo kính râm và đội mũ');
    } else if (uv <= 7.5) {
      return (label: 'Cao', color: Colors.orangeAccent, advice: 'Cần bôi kem chống nắng, mặc áo che chắn');
    } else if (uv <= 10.5) {
      return (label: 'Rất cao', color: Colors.redAccent, advice: 'Nguy hại cao, hạn chế ra nắng lúc trưa');
    } else {
      return (label: 'Nguy hiểm', color: Colors.purpleAccent, advice: 'Cực kỳ nguy hiểm, tránh ra ngoài trời');
    }
  }

  static String formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return isoString;
    }
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
